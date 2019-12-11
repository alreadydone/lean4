/-
Copyright (c) 2019 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import Init.Lean.Meta.Basic

namespace Lean
namespace Meta

private def strictOccursMaxAux (lvl : Level) : Level → Bool
| Level.max u v _ => strictOccursMaxAux u || strictOccursMaxAux v
| u               => u != lvl && lvl.occurs u

/--
  Return true iff `lvl` occurs in `max u_1 ... u_n` and `lvl != u_i` for all `i in [1, n]`.
  That is, `lvl` is a proper level subterm of some `u_i`. -/
private def strictOccursMax (lvl : Level) : Level → Bool
| Level.max u v _ => strictOccursMaxAux lvl u || strictOccursMaxAux lvl v
| _               => false

/-- `mkMaxArgsDiff mvarId (max u_1 ... (mvar mvarId) ... u_n) v` => `max v u_1 ... u_n` -/
private def mkMaxArgsDiff (mvarId : MVarId) : Level → Level → Level
| Level.max u v _,     acc => mkMaxArgsDiff v $ mkMaxArgsDiff u acc
| l@(Level.mvar id _), acc => if id != mvarId then mkLevelMax acc l else acc
| l,                   acc => mkLevelMax acc l

/--
  Solve `?m =?= max ?m v` by creating a fresh metavariable `?n`
  and assigning `?m := max ?n v` -/
private def solveSelfMax (mvarId : MVarId) (v : Level) : MetaM Unit := do
n ← mkFreshLevelMVar;
assignLevelMVar mvarId $ mkMaxArgsDiff mvarId v n

private def postponeIsLevelDefEq (lhs : Level) (rhs : Level) : MetaM Unit :=
modify $ fun s => { postponed := s.postponed.push { lhs := lhs, rhs := rhs }, .. s }

inductive LevelConstraintKind
| mvarEq         -- ?m =?= l         where ?m does not occur in l
| mvarEqSelfMax  -- ?m =?= max ?m l  where ?m does not occur in l
| other

private def getLevelConstraintKind (u v : Level) : MetaM LevelConstraintKind :=
match u with
| Level.mvar mvarId _ =>
  condM (isReadOnlyLevelMVar mvarId)
    (pure LevelConstraintKind.other)
    (if !u.occurs v then pure LevelConstraintKind.mvarEq
     else if !strictOccursMax u v then pure LevelConstraintKind.mvarEqSelfMax
     else pure LevelConstraintKind.other)
| _ =>
  pure LevelConstraintKind.other

partial def isLevelDefEqAux : Level → Level → MetaM Bool
| Level.succ lhs _, Level.succ rhs _ => isLevelDefEqAux lhs rhs
| lhs, rhs =>
  if lhs == rhs then
    pure true
  else do
    trace! `Meta.isLevelDefEq.step (lhs ++ " =?= " ++ rhs);
    lhs' ← instantiateLevelMVars lhs;
    let lhs' := lhs'.normalize;
    rhs' ← instantiateLevelMVars rhs;
    let rhs' := rhs'.normalize;
    if lhs != lhs' || rhs != rhs' then
      isLevelDefEqAux lhs' rhs'
    else do
      mctx ← getMCtx;
      if !mctx.hasAssignableLevelMVar lhs && !mctx.hasAssignableLevelMVar rhs then do
        ctx ← read;
        if ctx.config.isDefEqStuckEx && (lhs.isMVar || rhs.isMVar) then
          throwEx $ Exception.isLevelDefEqStuck lhs rhs
        else
          pure false
      else do
        k ← getLevelConstraintKind lhs rhs;
        match k with
        | LevelConstraintKind.mvarEq        => do assignLevelMVar lhs.mvarId! rhs; pure true
        | LevelConstraintKind.mvarEqSelfMax => do solveSelfMax lhs.mvarId! rhs; pure true
        | _ => do
          k ← getLevelConstraintKind rhs lhs;
          match k with
          | LevelConstraintKind.mvarEq        => do assignLevelMVar rhs.mvarId! lhs; pure true
          | LevelConstraintKind.mvarEqSelfMax => do solveSelfMax rhs.mvarId! lhs; pure true
          | _ =>
            if lhs.isMVar || rhs.isMVar then
              pure false
            else if lhs.isSucc || rhs.isSucc then
              match lhs.dec, rhs.dec with
              | some lhs', some rhs' => isLevelDefEqAux lhs' rhs'
              | _,         _         => do postponeIsLevelDefEq lhs rhs; pure true
            else do postponeIsLevelDefEq lhs rhs; pure true

def isListLevelDefEqAux : List Level → List Level → MetaM Bool
| [],    []    => pure true
| u::us, v::vs => isLevelDefEqAux u v <&&> isListLevelDefEqAux us vs
| _,     _     => pure false

private def getNumPostponed : MetaM Nat := do
s ← get; pure s.postponed.size

private def getResetPostponed : MetaM (PersistentArray PostponedEntry) := do
s ← get;
let ps := s.postponed;
modify $ fun s => { postponed := {}, .. s };
pure ps

private def processPostponedStep : MetaM Bool :=
traceCtx `Meta.isLevelDefEq.postponed.step $ do
  ps ← getResetPostponed;
  ps.foldlM
    (fun (r : Bool) (p : PostponedEntry) =>
      if r then
        isLevelDefEqAux p.lhs p.rhs
      else
        pure false)
    true

private partial def processPostponedAux : Unit → MetaM Bool
| _ => do
  numPostponed ← getNumPostponed;
  if numPostponed == 0 then
    pure true
  else do
    trace! `Meta.isLevelDefEq.postponed ("processing #" ++ toString numPostponed ++ " postponed is-def-eq level constraints");
    r ← processPostponedStep;
    if !r then
      pure r
    else do
      numPostponed' ← getNumPostponed;
      if numPostponed' == 0 then
        pure true
      else if numPostponed' < numPostponed then
        processPostponedAux ()
      else do
        trace! `Meta.isLevelDefEq.postponed (format "no progress solving pending is-def-eq level constraints");
        pure false

private def processPostponed : MetaM Bool := do
numPostponed ← getNumPostponed;
if numPostponed == 0 then pure true
else traceCtx `Meta.isLevelDefEq.postponed $ processPostponedAux ()


private def restore (env : Environment) (mctx : MetavarContext) (postponed : PersistentArray PostponedEntry) : MetaM Unit :=
modify $ fun s => { env := env, mctx := mctx, postponed := postponed, .. s }

/--
  `try x` executes `x` and process all postponed universe level constraints produced by `x`.
  We keep the modifications only if both return `true`.

  Remark: postponed universe level constraints must be solved before returning. Otherwise,
  we don't know whether `x` really succeeded. -/
@[specialize] def try (x : MetaM Bool) : MetaM Bool := do
s ← get;
let env       := s.env;
let mctx      := s.mctx;
let postponed := s.postponed;
modify $ fun s => { postponed := {}, .. s };
catch
  (condM x
    (condM processPostponed
      (pure true)
      (do restore env mctx postponed; pure false))
    (do restore env mctx postponed; pure false))
  (fun ex => do restore env mctx postponed; throw ex)

@[specialize] def tryOpt {α} (x : MetaM (Option α)) : MetaM (Option α) := do
s ← get;
let env       := s.env;
let mctx      := s.mctx;
let postponed := s.postponed;
modify $ fun s => { postponed := {}, .. s };
catch
  (do a? ← x;
      match a? with
      | some a =>
        condM processPostponed
          (pure (some a))
          (do restore env mctx postponed; pure none)
      | none   => do restore env mctx postponed; pure none)
  (fun ex => do restore env mctx postponed; throw ex)

/- Public interface -/

def isLevelDefEq (u v : Level) : MetaM Bool :=
traceCtx `Meta.isLevelDefEq $ do
  b ← try $ isLevelDefEqAux u v;
  trace! `Meta.isLevelDefEq (u ++ " =?= " ++ v ++ " ... " ++ if b then "success" else "failure");
  pure b

def isExprDefEq (t s : Expr) : MetaM Bool :=
traceCtx `Meta.isDefEq $ do
  b ← try $ isExprDefEqAux t s;
  trace! `Meta.isDefEq (t ++ " =?= " ++ s ++ " ... " ++ if b then "success" else "failure");
  pure b

abbrev isDefEq := @isExprDefEq

@[init] private def regTraceClasses : IO Unit := do
registerTraceClass `Meta.isLevelDefEq;
registerTraceClass `Meta.isLevelDefEq.step;
registerTraceClass `Meta.isLevelDefEq.postponed

end Meta
end Lean
