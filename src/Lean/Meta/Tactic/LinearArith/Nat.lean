/-
Copyright (c) 2022 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
import Lean.Meta.Check
import Lean.Meta.Offset
import Lean.Meta.KExprMap

namespace Lean.Meta.Linear.Nat

deriving instance Repr for Nat.Linear.Expr

abbrev LinearExpr  := Nat.Linear.Expr
abbrev LinearCnstr := Nat.Linear.ExprCnstr
abbrev PolyExpr := Nat.Linear.Poly

def LinearExpr.toExpr (e : LinearExpr) : Expr :=
  open Nat.Linear.Expr in
  match e with
  | num v    => mkApp (mkConst ``num) (mkNatLit v)
  | var i    => mkApp (mkConst ``var) (mkNatLit i)
  | add a b  => mkApp2 (mkConst ``add) (toExpr a) (toExpr b)
  | mulL k a => mkApp2 (mkConst ``mulL) (mkNatLit k) (toExpr a)
  | mulR a k => mkApp2 (mkConst ``mulL) (toExpr a) (mkNatLit k)

instance : ToExpr LinearExpr where
  toExpr a := a.toExpr
  toTypeExpr := mkConst ``Nat.Linear.Expr

protected def LinearCnstr.toExpr (c : LinearCnstr) : Expr :=
   mkApp3 (mkConst ``Nat.Linear.ExprCnstr.mk) (toExpr c.eq) (LinearExpr.toExpr c.lhs) (LinearExpr.toExpr c.rhs)

instance : ToExpr LinearCnstr where
  toExpr a   := a.toExpr
  toTypeExpr := mkConst ``Nat.Linear.ExprCnstr

open Nat.Linear.Expr in
def LinearExpr.toArith (ctx : Array Expr) (e : LinearExpr) : MetaM Expr := do
  match e with
  | num v    => return mkNatLit v
  | var i    => return ctx[i]
  | add a b  => mkAdd (← toArith ctx a) (← toArith ctx b)
  | mulL k a => mkMul (mkNatLit k) (← toArith ctx a)
  | mulR a k => mkMul (← toArith ctx a) (mkNatLit k)

def LinearCnstr.toArith (ctx : Array Expr) (c : LinearCnstr) : MetaM Expr := do
  if c.eq then
    mkEq (← LinearExpr.toArith ctx c.lhs) (← LinearExpr.toArith ctx c.rhs)
  else
    return mkApp4 (mkConst ``LE.le [levelZero]) (mkConst ``Nat) (mkConst ``instLENat) (← LinearExpr.toArith ctx c.lhs) (← LinearExpr.toArith ctx c.rhs)

namespace ToLinear

structure State where
  varMap : KExprMap Nat := {} -- It should be fine to use `KExprMap` here because the mapping should be small and few HeadIndex collisions.
  vars   : Array Expr := #[]

abbrev M := StateRefT State MetaM

open Nat.Linear.Expr

def addAsVar (e : Expr) : M LinearExpr := do
  if let some x ← (← get).varMap.find? e then
    return var x
  else
    let x := (← get).vars.size
    let s ← get
    set { varMap := (← s.varMap.insert e x), vars := s.vars.push e : State }
    return var x

partial def toLinearExpr (e : Expr) : M LinearExpr := do
  match e with
  | Expr.lit (Literal.natVal n) _ => return num n
  | Expr.mdata _ e _              => toLinearExpr e
  | Expr.const ``Nat.zero ..      => return num 0
  | Expr.app ..                   => visit e
  | Expr.mvar ..                  => visit e
  | _                             => addAsVar e
where
  visit (e : Expr) : M LinearExpr := do
    let f := e.getAppFn
    match f with
    | Expr.mvar .. =>
      let eNew ← instantiateMVars e
      if eNew != e then
        toLinearExpr eNew
      else
        addAsVar e
    | Expr.const declName .. =>
      let numArgs := e.getAppNumArgs
      if declName == ``Nat.succ && numArgs == 1 then
        return inc (← toLinearExpr e.appArg!)
      else if declName == ``Nat.add && numArgs == 2 then
        return add (← toLinearExpr (e.getArg! 0)) (← toLinearExpr (e.getArg! 1))
      else if declName == ``Nat.mul && numArgs == 2 then
        match (← evalNat (e.getArg! 0) |>.run) with
        | some k => return mulL k (← toLinearExpr (e.getArg! 1))
        | none => match (← evalNat (e.getArg! 1) |>.run) with
          | some k => return mulR (← toLinearExpr (e.getArg! 0)) k
          | none => addAsVar e
      else if isNatProjInst declName numArgs then
        if let some e ← unfoldProjInst? e then
          toLinearExpr e
        else
          addAsVar e
      else
        addAsVar e
    | _ => addAsVar e

partial def toLinearCnstr? (e : Expr) : M (Option LinearCnstr) := do
  let f := e.getAppFn
  match f with
  | Expr.mvar .. =>
    let eNew ← instantiateMVars e
    if eNew != e then
      toLinearCnstr? eNew
    else
      return none
  | Expr.const declName .. =>
    let numArgs := e.getAppNumArgs
    if declName == ``Eq && numArgs == 3 then
      return some { eq := true, lhs := (← toLinearExpr (e.getArg! 1)), rhs := (← toLinearExpr (e.getArg! 2)) }
    else if declName == ``Nat.le && numArgs == 2 then
      return some { eq := false, lhs := (← toLinearExpr (e.getArg! 0)), rhs := (← toLinearExpr (e.getArg! 1)) }
    else if declName == ``Nat.lt && numArgs == 2 then
      return some { eq := false, lhs := (← toLinearExpr (e.getArg! 0)).inc, rhs := (← toLinearExpr (e.getArg! 1)) }
    else if numArgs == 4 && (declName == ``GE.ge || declName == ``GT.gt) then
      if let some e ← unfoldDefinition? e then
        toLinearCnstr? e
      else
        return none
    else if numArgs == 4 && (declName == ``LE.le || declName == ``LT.lt) then
      if (← isDefEq (e.getArg! 0) (mkConst ``Nat)) then
        if let some e ← unfoldProjInst? e then
          toLinearCnstr? e
        else
          return none
      else
        return none
    else
      return none
  | _ => return none

def run (x : M α) : MetaM (α × Array Expr) := do
  let (a, s) ← x.run {}
  return (a, s.vars)

end ToLinear

open ToLinear (toLinearCnstr? toLinearExpr)

def toContextExpr (ctx : Array Expr) : MetaM Expr := do
  mkListLit (mkConst ``Nat) ctx.toList

def reflTrue : Expr :=
  mkApp2 (mkConst ``Eq.refl [levelOne]) (mkConst ``Bool) (mkConst ``Bool.true)

def simpCnstrPos? (e : Expr) : MetaM (Option (Expr × Expr)) := do
  let (some c, ctx) ← ToLinear.run (ToLinear.toLinearCnstr? e) | return none
  let c₁ := c.toPoly
  let c₂ := c₁.norm
  if c₂.isUnsat then
    let p := mkApp3 (mkConst ``Nat.Linear.ExprCnstr.eq_false_of_isUnsat) (← toContextExpr ctx) (toExpr c) reflTrue
    return some (mkConst ``False, p)
  else if c₂.isValid then
    let p := mkApp3 (mkConst ``Nat.Linear.ExprCnstr.eq_true_of_isValid) (← toContextExpr ctx) (toExpr c) reflTrue
    return some (mkConst ``True, p)
  else if c₁ != c₂ then
    let c₂ : LinearCnstr := c₂.toExpr
    let p := mkApp4 (mkConst ``Nat.Linear.ExprCnstr.eq_of_toNormPoly_eq) (← toContextExpr ctx) (toExpr c) (toExpr c₂) reflTrue
    let r ← c₂.toArith ctx
    return some (r, p)
  else
    return none

def simpCnstr? (e : Expr) : MetaM (Option (Expr × Expr)) := do
  if let some arg := e.not? then
    let mut eNew?   := none
    let mut thmName := Name.anonymous
    if arg.isAppOfArity ``LE.le 4 then
      eNew?   := some (← mkLE (← mkAdd (arg.getArg! 3) (mkNatLit 1)) (arg.getArg! 2))
      thmName := ``Nat.not_le_eq
    else if arg.isAppOfArity ``GE.ge 4 then
      eNew?   := some (← mkLE (← mkAdd (arg.getArg! 2) (mkNatLit 1)) (arg.getArg! 3))
      thmName := ``Nat.not_ge_eq
    else if arg.isAppOfArity ``LT.lt 4 then
      eNew?   := some (← mkLE (arg.getArg! 3) (arg.getArg! 2))
      thmName := ``Nat.not_lt_eq
    else if arg.isAppOfArity ``GT.gt 4 then
      eNew?   := some (← mkLE (arg.getArg! 2) (arg.getArg! 3))
      thmName := ``Nat.not_gt_eq
    if let some eNew := eNew? then
      if let some (eNew', h₂) ← simpCnstrPos? eNew then
        let h₁ := mkApp2 (mkConst thmName) (arg.getArg! 2) (arg.getArg! 3)
        let h  := mkApp6 (mkConst ``Eq.trans [levelOne]) (mkSort levelZero) e eNew eNew' h₁ h₂
        return some (eNew', h)
      else
        return none
    else
      return none
  else
    simpCnstrPos? e

def simpExpr? (e : Expr) : MetaM (Option (Expr × Expr)) := do
  let (e, ctx) ← ToLinear.run (ToLinear.toLinearExpr e)
  let p  := e.toPoly
  let p' := p.norm
  if p'.length < p.length then
    -- We only return some if monomials were fused
    let e' : LinearExpr := p'.toExpr
    let p := mkApp4 (mkConst ``Nat.Linear.Expr.eq_of_toNormPoly_eq) (← toContextExpr ctx) (toExpr e) (toExpr e') reflTrue
    let r ← e'.toArith ctx
    return some (r, p)
  else
    return none

end Lean.Meta.Linear.Nat
