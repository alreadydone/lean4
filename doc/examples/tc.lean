/-|
# A Certified Type Checker

In this example, we build a certified type checker for a simple expression
language.

Remark: this example is based on an example in the book [Certified Programming with Dependent Types](http://adam.chlipala.net/cpdt/) by Adam Chlipala.
-/
inductive Expr where
  | nat  : Nat → Expr
  | plus : Expr → Expr → Expr
  | bool : Bool → Expr
  | and  : Expr → Expr → Expr

/-|
We define a simple language of types using the inductive datatype `Ty`, and
its typing rules using the inductive predicate `HasType`.
-/
inductive Ty where
  | nat
  | bool
  deriving DecidableEq

inductive HasType : Expr → Ty → Prop
  | nat  : HasType (.nat v) .nat
  | plus : HasType a .nat → HasType b .nat → HasType (.plus a b) .nat
  | bool : HasType (.bool v) .bool
  | and  : HasType a .bool → HasType b .bool → HasType (.and a b) .bool

/-|
We can easily show that if `e` has type `t₁` and type `t₂`, then `t₁` and `t₂` must be equal
by using the the `cases` tactic. This tactic creates a new subgoal for every constructor,
and automatically discharges unreachable cases. The tactic combinator `tac₁ <;> tac₂` applies
`tac₂` to each subgoal produced by `tac₁`. Then, the tactic `rfl` is used to close all produced
goals using reflexivity.
-/
theorem HasType.det (h₁ : HasType e t₁) (h₂ : HasType e t₂) : t₁ = t₂ := by
  cases h₁ <;> cases h₂ <;> rfl

/-|
The inductive type `Maybe p` has two contructors: `found a h` and `unknown`.
The former contains an element `a : α` and a proof that `a` satisfies the predicate `p`.
The constructor `unknown` is used to encode "failure".
-/

inductive Maybe (p : α → Prop) where
  | found : (a : α) → p a → Maybe p
  | unknown

/-|
We define a notation for `Maybe` that is similar to the builtin notation for the Lean builtin type `Subtype`.
-/
notation "{{ " x " | " p " }}" => Maybe (fun x => p)

/-|
The function `Expr.typeCheck e` returns a type `ty` and a proof that `e` has type `ty`,
or `unknown`.
Recall that, `def Expr.typeCheck ...` in Lean is notation for `namespace Expr def typeCheck ... end Expr`.
The term `.found .nat .nat` is sugar for `Maybe.found Ty.nat HasType.nat`. Lean can infer the namespaces using
the expected types.
-/
def Expr.typeCheck (e : Expr) : {{ ty | HasType e ty }} :=
  match e with
  | nat ..   => .found .nat .nat
  | bool ..  => .found .bool .bool
  | plus a b =>
    match a.typeCheck, b.typeCheck with
    | .found .nat h₁, .found .nat h₂ => .found .nat (.plus h₁ h₂)
    | _, _ => .unknown
  | and a b =>
    match a.typeCheck, b.typeCheck with
    | .found .bool h₁, .found .bool h₂ => .found .bool (.and h₁ h₂)
    | _, _ => .unknown

theorem Expr.typeCheck_correct (h₁ : HasType e ty) (h₂ : e.typeCheck ≠ .unknown) : e.typeCheck = .found ty h := by
  revert h₂
  cases typeCheck e with
  | found ty' h' => intro; have := HasType.det h₁ h'; subst this; rfl
  | unknown => intros; contradiction

/-|
Now, we prove that if `Expr.typeCheck e` returns `Maybe.unknown`, then forall `ty`, `HasType e ty` does not hold.
The notation `e.typeCheck` is sugar for `Expr.typeCheck e`. Lean can infer this because we explicitly said that `e` has type `Expr`.
The proof is by induction on `e` and case analysis. The tactic `rename_i` is used to to rename "inaccessible" variables.
We say a variable is inaccessible if it is introduced by a tactic (e.g., `cases`) or has been shadowed by another variable introduced
by the user. Note that the tactic `simp [typeCheck]` is applied to all goal generated by the `induction` tactic, and closes
the cases corresponding to the constructors `Expr.nat` and `Expr.bool`.
-/
theorem Expr.typeCheck_complete {e : Expr} : e.typeCheck = .unknown → ¬ HasType e ty := by
  induction e with simp [typeCheck]
  | plus a b iha ihb =>
    split
    next => intros; contradiction
    next ra rb hnp => -- Recall that hnp is a hypothesis generated by the `split` tactic that asserts the previous case was not taken
      intro h ht
      cases ht with
      | plus h₁ h₂ => exact hnp h₁ h₂ (typeCheck_correct h₁ (iha · h₁)) (typeCheck_correct h₂ (ihb · h₂))
  | and a b iha ihb =>
    split
    next => intros; contradiction
    next ra rb hnp =>
      intro h ht
      cases ht with
      | and h₁ h₂ =>  exact hnp h₁ h₂ (typeCheck_correct h₁ (iha · h₁)) (typeCheck_correct h₂ (ihb · h₂))

/-|
Finally, we show that type checking for `e` can be decided using `Expr.typeCheck`.
-/
instance (e : Expr) (t : Ty) : Decidable (HasType e t) :=
  match h' : e.typeCheck with
  | .found t' ht' =>
    if heq : t = t' then
      isTrue (heq ▸ ht')
    else
      isFalse fun ht => heq (HasType.det ht ht')
  | .unknown => isFalse (Expr.typeCheck_complete h')
