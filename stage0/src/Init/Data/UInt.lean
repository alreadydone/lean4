/-
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import Init.Data.Fin.Basic
import Init.System.Platform

open Nat

def uint8Sz : Nat := 256
structure UInt8 :=
  (val : Fin uint8Sz)

@[extern "lean_uint8_of_nat"]
def UInt8.ofNat (n : @& Nat) : UInt8 := ⟨Fin.ofNat n⟩
abbrev Nat.toUInt8 := UInt8.ofNat
@[extern "lean_uint8_to_nat"]
def UInt8.toNat (n : UInt8) : Nat := n.val.val
@[extern c inline "#1 + #2"]
def UInt8.add (a b : UInt8) : UInt8 := ⟨a.val + b.val⟩
@[extern c inline "#1 - #2"]
def UInt8.sub (a b : UInt8) : UInt8 := ⟨a.val - b.val⟩
@[extern c inline "#1 * #2"]
def UInt8.mul (a b : UInt8) : UInt8 := ⟨a.val * b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 / #2"]
def UInt8.div (a b : UInt8) : UInt8 := ⟨a.val / b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 % #2"]
def UInt8.mod (a b : UInt8) : UInt8 := ⟨a.val % b.val⟩
@[extern "lean_uint8_modn"]
def UInt8.modn (a : UInt8) (n : @& Nat) : UInt8 := ⟨a.val %ₙ n⟩
@[extern c inline "#1 & #2"]
def UInt8.land (a b : UInt8) : UInt8 := ⟨Fin.land a.val b.val⟩
@[extern c inline "#1 | #2"]
def UInt8.lor (a b : UInt8) : UInt8 := ⟨Fin.lor a.val b.val⟩
def UInt8.lt (a b : UInt8) : Prop := a.val < b.val
def UInt8.le (a b : UInt8) : Prop := a.val ≤ b.val

instance : OfNat UInt8     := ⟨UInt8.ofNat⟩
instance : Add UInt8       := ⟨UInt8.add⟩
instance : Sub UInt8       := ⟨UInt8.sub⟩
instance : Mul UInt8       := ⟨UInt8.mul⟩
instance : Mod UInt8       := ⟨UInt8.mod⟩
instance : ModN UInt8      := ⟨UInt8.modn⟩
instance : Div UInt8       := ⟨UInt8.div⟩
instance : HasLess UInt8   := ⟨UInt8.lt⟩
instance : HasLessEq UInt8 := ⟨UInt8.le⟩
instance : Inhabited UInt8 := ⟨0⟩

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 == #2"]
def UInt8.decEq (a b : UInt8) : Decidable (a = b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => if h : n = m then isTrue (h ▸ rfl) else isFalse (fun h' => UInt8.noConfusion h' (fun h' => absurd h' h))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 < #2"]
def UInt8.decLt (a b : UInt8) : Decidable (a < b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n < m))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 <= #2"]
def UInt8.decLe (a b : UInt8) : Decidable (a ≤ b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n <= m))

instance : DecidableEq UInt8 := UInt8.decEq
instance (a b : UInt8) : Decidable (a < b) := UInt8.decLt a b
instance (a b : UInt8) : Decidable (a ≤ b) := UInt8.decLe a b

def uint16Sz : Nat := 65536
structure UInt16 :=
  (val : Fin uint16Sz)

@[extern "lean_uint16_of_nat"]
def UInt16.ofNat (n : @& Nat) : UInt16 := ⟨Fin.ofNat n⟩
abbrev Nat.toUInt16 := UInt16.ofNat
@[extern "lean_uint16_to_nat"]
def UInt16.toNat (n : UInt16) : Nat := n.val.val
@[extern c inline "#1 + #2"]
def UInt16.add (a b : UInt16) : UInt16 := ⟨a.val + b.val⟩
@[extern c inline "#1 - #2"]
def UInt16.sub (a b : UInt16) : UInt16 := ⟨a.val - b.val⟩
@[extern c inline "#1 * #2"]
def UInt16.mul (a b : UInt16) : UInt16 := ⟨a.val * b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 / #2"]
def UInt16.div (a b : UInt16) : UInt16 := ⟨a.val / b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 % #2"]
def UInt16.mod (a b : UInt16) : UInt16 := ⟨a.val % b.val⟩
@[extern "lean_uint16_modn"]
def UInt16.modn (a : UInt16) (n : @& Nat) : UInt16 := ⟨a.val %ₙ n⟩
@[extern c inline "#1 & #2"]
def UInt16.land (a b : UInt16) : UInt16 := ⟨Fin.land a.val b.val⟩
@[extern c inline "#1 | #2"]
def UInt16.lor (a b : UInt16) : UInt16 := ⟨Fin.lor a.val b.val⟩
def UInt16.lt (a b : UInt16) : Prop := a.val < b.val
def UInt16.le (a b : UInt16) : Prop := a.val ≤ b.val


instance : OfNat UInt16     := ⟨UInt16.ofNat⟩
instance : Add UInt16       := ⟨UInt16.add⟩
instance : Sub UInt16       := ⟨UInt16.sub⟩
instance : Mul UInt16       := ⟨UInt16.mul⟩
instance : Mod UInt16       := ⟨UInt16.mod⟩
instance : ModN UInt16      := ⟨UInt16.modn⟩
instance : Div UInt16       := ⟨UInt16.div⟩
instance : HasLess UInt16   := ⟨UInt16.lt⟩
instance : HasLessEq UInt16 := ⟨UInt16.le⟩
instance : Inhabited UInt16 := ⟨0⟩

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 == #2"]
def UInt16.decEq (a b : UInt16) : Decidable (a = b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => if h : n = m then isTrue (h ▸ rfl) else isFalse (fun h' => UInt16.noConfusion h' (fun h' => absurd h' h))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 < #2"]
def UInt16.decLt (a b : UInt16) : Decidable (a < b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n < m))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 <= #2"]
def UInt16.decLe (a b : UInt16) : Decidable (a ≤ b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n <= m))

instance : DecidableEq UInt16 := UInt16.decEq
instance (a b : UInt16) : Decidable (a < b) := UInt16.decLt a b
instance (a b : UInt16) : Decidable (a ≤ b) := UInt16.decLe a b

def uint32Sz : Nat := 4294967296
structure UInt32 :=
  (val : Fin uint32Sz)

@[extern "lean_uint32_of_nat"]
def UInt32.ofNat (n : @& Nat) : UInt32 := ⟨Fin.ofNat n⟩
@[extern "lean_uint32_of_nat"]
def UInt32.ofNat' (n : Nat) (h : n < uint32Sz) : UInt32 := ⟨⟨n, h⟩⟩
abbrev Nat.toUInt32 := UInt32.ofNat
@[extern "lean_uint32_to_nat"]
def UInt32.toNat (n : UInt32) : Nat := n.val.val
@[extern c inline "#1 + #2"]
def UInt32.add (a b : UInt32) : UInt32 := ⟨a.val + b.val⟩
@[extern c inline "#1 - #2"]
def UInt32.sub (a b : UInt32) : UInt32 := ⟨a.val - b.val⟩
@[extern c inline "#1 * #2"]
def UInt32.mul (a b : UInt32) : UInt32 := ⟨a.val * b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 / #2"]
def UInt32.div (a b : UInt32) : UInt32 := ⟨a.val / b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 % #2"]
def UInt32.mod (a b : UInt32) : UInt32 := ⟨a.val % b.val⟩
@[extern "lean_uint32_modn"]
def UInt32.modn (a : UInt32) (n : @& Nat) : UInt32 := ⟨a.val %ₙ n⟩
@[extern c inline "#1 & #2"]
def UInt32.land (a b : UInt32) : UInt32 := ⟨Fin.land a.val b.val⟩
@[extern c inline "#1 | #2"]
def UInt32.lor (a b : UInt32) : UInt32 := ⟨Fin.lor a.val b.val⟩
def UInt32.lt (a b : UInt32) : Prop := a.val < b.val
def UInt32.le (a b : UInt32) : Prop := a.val ≤ b.val
@[extern c inline "((uint8_t)#1)"]
def UInt32.toUInt8 (a : UInt32) : UInt8 := a.toNat.toUInt8
@[extern c inline "((uint16_t)#1)"]
def UInt32.toUInt16 (a : UInt32) : UInt16 := a.toNat.toUInt16
@[extern c inline "((uint32_t)#1)"]
def UInt8.toUInt32 (a : UInt8) : UInt32 := a.toNat.toUInt32

instance : OfNat UInt32     := ⟨UInt32.ofNat⟩
instance : Add UInt32       := ⟨UInt32.add⟩
instance : Sub UInt32       := ⟨UInt32.sub⟩
instance : Mul UInt32       := ⟨UInt32.mul⟩
instance : Mod UInt32       := ⟨UInt32.mod⟩
instance : ModN UInt32      := ⟨UInt32.modn⟩
instance : Div UInt32       := ⟨UInt32.div⟩
instance : HasLess UInt32   := ⟨UInt32.lt⟩
instance : HasLessEq UInt32 := ⟨UInt32.le⟩
instance : Inhabited UInt32 := ⟨0⟩

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 == #2"]
def UInt32.decEq (a b : UInt32) : Decidable (a = b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => if h : n = m then isTrue (h ▸ rfl) else isFalse (fun h' => UInt32.noConfusion h' (fun h' => absurd h' h))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 < #2"]
def UInt32.decLt (a b : UInt32) : Decidable (a < b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n < m))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 <= #2"]
def UInt32.decLe (a b : UInt32) : Decidable (a ≤ b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n <= m))

@[extern c inline "#1 << #2"]
constant UInt32.shiftLeft (a b : UInt32) : UInt32 := (arbitrary Nat).toUInt32
@[extern c inline "#1 >> #2"]
constant UInt32.shiftRight (a b : UInt32) : UInt32 := (arbitrary Nat).toUInt32

instance : DecidableEq UInt32 := UInt32.decEq
instance (a b : UInt32) : Decidable (a < b) := UInt32.decLt a b
instance (a b : UInt32) : Decidable (a ≤ b) := UInt32.decLe a b

def uint64Sz : Nat := 18446744073709551616
structure UInt64 :=
  (val : Fin uint64Sz)

@[extern "lean_uint64_of_nat"]
def UInt64.ofNat (n : @& Nat) : UInt64 := ⟨Fin.ofNat n⟩
abbrev Nat.toUInt64 := UInt64.ofNat
@[extern "lean_uint64_to_nat"]
def UInt64.toNat (n : UInt64) : Nat := n.val.val
@[extern c inline "#1 + #2"]
def UInt64.add (a b : UInt64) : UInt64 := ⟨a.val + b.val⟩
@[extern c inline "#1 - #2"]
def UInt64.sub (a b : UInt64) : UInt64 := ⟨a.val - b.val⟩
@[extern c inline "#1 * #2"]
def UInt64.mul (a b : UInt64) : UInt64 := ⟨a.val * b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 / #2"]
def UInt64.div (a b : UInt64) : UInt64 := ⟨a.val / b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 % #2"]
def UInt64.mod (a b : UInt64) : UInt64 := ⟨a.val % b.val⟩
@[extern "lean_uint64_modn"]
def UInt64.modn (a : UInt64) (n : @& Nat) : UInt64 := ⟨a.val %ₙ n⟩
@[extern c inline "#1 & #2"]
def UInt64.land (a b : UInt64) : UInt64 := ⟨Fin.land a.val b.val⟩
@[extern c inline "#1 | #2"]
def UInt64.lor (a b : UInt64) : UInt64 := ⟨Fin.lor a.val b.val⟩
def UInt64.lt (a b : UInt64) : Prop := a.val < b.val
def UInt64.le (a b : UInt64) : Prop := a.val ≤ b.val
@[extern c inline "((uint8_t)#1)"]
def UInt64.toUInt8 (a : UInt64) : UInt8 := a.toNat.toUInt8
@[extern c inline "((uint16_t)#1)"]
def UInt64.toUInt16 (a : UInt64) : UInt16 := a.toNat.toUInt16
@[extern c inline "((uint32_t)#1)"]
def UInt64.toUInt32 (a : UInt64) : UInt32 := a.toNat.toUInt32
@[extern c inline "((uint64_t)#1)"]
def UInt32.toUInt64 (a : UInt32) : UInt64 := a.toNat.toUInt64

-- TODO(Leo): give reference implementation for shiftLeft and shiftRight, and define them for other UInt types
@[extern c inline "#1 << #2"]
constant UInt64.shiftLeft (a b : UInt64) : UInt64 := (arbitrary Nat).toUInt64
@[extern c inline "#1 >> #2"]
constant UInt64.shiftRight (a b : UInt64) : UInt64 := (arbitrary Nat).toUInt64

instance : OfNat UInt64     := ⟨UInt64.ofNat⟩
instance : Add UInt64       := ⟨UInt64.add⟩
instance : Sub UInt64       := ⟨UInt64.sub⟩
instance : Mul UInt64       := ⟨UInt64.mul⟩
instance : Mod UInt64       := ⟨UInt64.mod⟩
instance : ModN UInt64      := ⟨UInt64.modn⟩
instance : Div UInt64       := ⟨UInt64.div⟩
instance : HasLess UInt64   := ⟨UInt64.lt⟩
instance : HasLessEq UInt64 := ⟨UInt64.le⟩
instance : Inhabited UInt64 := ⟨0⟩

@[extern c inline "(uint64_t)#1"]
def Bool.toUInt64 (b : Bool) : UInt64 := if b then 1 else 0

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 == #2"]
def UInt64.decEq (a b : UInt64) : Decidable (a = b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => if h : n = m then isTrue (h ▸ rfl) else isFalse (fun h' => UInt64.noConfusion h' (fun h' => absurd h' h))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 < #2"]
def UInt64.decLt (a b : UInt64) : Decidable (a < b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n < m))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 <= #2"]
def UInt64.decLe (a b : UInt64) : Decidable (a ≤ b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n <= m))

instance : DecidableEq UInt64 := UInt64.decEq
instance (a b : UInt64) : Decidable (a < b) := UInt64.decLt a b
instance (a b : UInt64) : Decidable (a ≤ b) := UInt64.decLe a b

def usizeSz : Nat := (2:Nat) ^ System.Platform.numBits
structure USize :=
  (val : Fin usizeSz)

theorem usizeSzGt0 : usizeSz > 0 :=
  Nat.posPowOfPos System.Platform.numBits (Nat.zeroLtSucc _)

@[extern "lean_usize_of_nat"]
def USize.ofNat (n : @& Nat) : USize := ⟨Fin.ofNat' n usizeSzGt0⟩
abbrev Nat.toUSize := USize.ofNat
@[extern "lean_usize_to_nat"]
def USize.toNat (n : USize) : Nat := n.val.val
@[extern c inline "#1 + #2"]
def USize.add (a b : USize) : USize := ⟨a.val + b.val⟩
@[extern c inline "#1 - #2"]
def USize.sub (a b : USize) : USize := ⟨a.val - b.val⟩
@[extern c inline "#1 * #2"]
def USize.mul (a b : USize) : USize := ⟨a.val * b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 / #2"]
def USize.div (a b : USize) : USize := ⟨a.val / b.val⟩
@[extern c inline "#2 == 0 ? 0 : #1 % #2"]
def USize.mod (a b : USize) : USize := ⟨a.val % b.val⟩
@[extern "lean_usize_modn"]
def USize.modn (a : USize) (n : @& Nat) : USize := ⟨a.val %ₙ n⟩
@[extern c inline "#1 & #2"]
def USize.land (a b : USize) : USize := ⟨Fin.land a.val b.val⟩
@[extern c inline "#1 | #2"]
def USize.lor (a b : USize) : USize := ⟨Fin.lor a.val b.val⟩
@[extern c inline "#1"]
def UInt32.toUSize (a : UInt32) : USize := a.toNat.toUSize
@[extern c inline "((size_t)#1)"]
def UInt64.toUSize (a : UInt64) : USize := a.toNat.toUSize
@[extern c inline "(uint32_t)#1"]
def USize.toUInt32 (a : USize) : UInt32 := a.toNat.toUInt32

-- TODO(Leo): give reference implementation for shiftLeft and shiftRight, and define them for other UInt types
@[extern c inline "#1 << #2"]
constant USize.shiftLeft (a b : USize) : USize := (arbitrary Nat).toUSize
@[extern c inline "#1 >> #2"]
constant USize.shiftRight (a b : USize) : USize := (arbitrary Nat).toUSize
def USize.lt (a b : USize) : Prop := a.val < b.val
def USize.le (a b : USize) : Prop := a.val ≤ b.val

instance : OfNat USize     := ⟨USize.ofNat⟩
instance : Add USize       := ⟨USize.add⟩
instance : Sub USize       := ⟨USize.sub⟩
instance : Mul USize       := ⟨USize.mul⟩
instance : Mod USize       := ⟨USize.mod⟩
instance : ModN USize      := ⟨USize.modn⟩
instance : Div USize       := ⟨USize.div⟩
instance : HasLess USize   := ⟨USize.lt⟩
instance : HasLessEq USize := ⟨USize.le⟩
instance : Inhabited USize := ⟨0⟩

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 == #2"]
def USize.decEq (a b : USize) : Decidable (a = b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => if h : n = m then isTrue (h ▸ rfl) else isFalse (fun h' => USize.noConfusion h' (fun h' => absurd h' h))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 < #2"]
def USize.decLt (a b : USize) : Decidable (a < b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n < m))

set_option bootstrap.gen_matcher_code false in
@[extern c inline "#1 <= #2"]
def USize.decLe (a b : USize) : Decidable (a ≤ b) :=
  match a, b with
  | ⟨n⟩, ⟨m⟩ => inferInstanceAs (Decidable (n <= m))

instance : DecidableEq USize := USize.decEq
instance (a b : USize) : Decidable (a < b) := USize.decLt a b
instance (a b : USize) : Decidable (a ≤ b) := USize.decLe a b

theorem USize.modnLt {m : Nat} : ∀ (u : USize), m > 0 → USize.toNat (u %ₙ m) < m
  | ⟨u⟩, h => Fin.modnLt u h
