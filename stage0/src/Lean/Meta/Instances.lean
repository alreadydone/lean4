/-
Copyright (c) 2019 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
import Lean.Meta.DiscrTree

namespace Lean.Meta

structure InstanceEntry :=
  (keys        : Array DiscrTree.Key)
  (val         : Expr)
  (globalName? : Option Name := none)

structure Instances :=
  (discrTree       : DiscrTree Expr := DiscrTree.empty )
  (globalInstances : NameSet := {})

instance : Inhabited Instances := {
  default := {}
}

def addInstanceEntry (d : Instances) (e : InstanceEntry) : Instances := {
  d with
    discrTree := d.discrTree.insertCore e.keys e.val
    globalInstances := match e.globalName? with
      | some n => d.globalInstances.insert n
      | none   => d.globalInstances
}

builtin_initialize instanceExtension : SimplePersistentEnvExtension InstanceEntry Instances ←
  registerSimplePersistentEnvExtension {
    name          := `instanceExt,
    addEntryFn    := addInstanceEntry,
    addImportedFn := fun es => (mkStateFromImportedEntries addInstanceEntry {} es)
  }

private def mkInstanceKey (e : Expr) : MetaM (Array DiscrTree.Key) := do
  let type ← inferType e
  withNewMCtxDepth do
    let (_, _, type) ← forallMetaTelescopeReducing type
    DiscrTree.mkPath type

@[export lean_add_instance]
def addGlobalInstanceImp (env : Environment) (constName : Name) : IO Environment := do
  match env.find? constName with
  | none => throw <| IO.userError s!"unknown constant '{constName}'"
  | some cinfo =>
    let c := mkConst constName (cinfo.lparams.map mkLevelParam)
    let (keys, s, _) ← (mkInstanceKey c).toIO {} { env := env } {} {}
    return instanceExtension.addEntry s.env { keys := keys, val := c, globalName? := constName }

def addGlobalInstance [Monad m] [MonadEnv m] [MonadLiftT IO m] (declName : Name) : m Unit := do
  let env ← getEnv
  let env ← Meta.addGlobalInstanceImp env declName
  setEnv env

builtin_initialize
  registerBuiltinAttribute {
    name  := `instance,
    descr := "type class instance",
    add   := fun declName args persistent => do
      if args.hasArgs then throwError "invalid attribute 'instance', unexpected argument"
      unless persistent do throwError "invalid attribute 'instance', must be persistent"
      addGlobalInstance declName
  }

@[export lean_is_instance]
def isGlobalInstance (env : Environment) (declName : Name) : Bool :=
  Meta.instanceExtension.getState env |>.globalInstances.contains declName

def getGlobalInstancesIndex : MetaM (DiscrTree Expr) :=
  return Meta.instanceExtension.getState (← getEnv) |>.discrTree

/- Default instance support -/

structure DefaultInstanceEntry :=
  (className    : Name)
  (instanceName : Name)

structure DefaultInstances :=
  (defaultInstances : NameMap (List Name) := {})

instance : Inhabited DefaultInstances := {
  default := {}
}

def addDefaultInstanceEntry (d : DefaultInstances) (e : DefaultInstanceEntry) : DefaultInstances :=
  match d.defaultInstances.find? e.className with
  | some insts => { defaultInstances := d.defaultInstances.insert e.className <| e.instanceName :: insts }
  | none       => { defaultInstances := d.defaultInstances.insert e.className [e.instanceName] }

builtin_initialize defaultInstanceExtension : SimplePersistentEnvExtension DefaultInstanceEntry DefaultInstances ←
  registerSimplePersistentEnvExtension {
    name          := `defaultInstanceExt,
    addEntryFn    := addDefaultInstanceEntry,
    addImportedFn := fun es => (mkStateFromImportedEntries addDefaultInstanceEntry {} es)
  }

def addDefaultInstanceImp (env : Environment) (declName : Name) : IO Environment := do
  match env.find? declName with
  | none => throw <| IO.userError s!"unknown constant '{declName}'"
  | some info =>
    unless info.lparams.isEmpty do
      throw <| IO.userError s!"invalid default instance '{declName}', it has universe parameters"
    match info.type.getAppFn with
    | Expr.const className _ _ =>
      unless isClass env className do
        throw <| IO.userError s!"invalid default instance '{declName}', it has type '({className} ...)', but {className}' is not a type class"
      return defaultInstanceExtension.addEntry env { className := className, instanceName := declName }
    | _ => throw <| IO.userError s!"invalid default instance '{declName}', type must be of the form '(C ...)' where 'C' is a type class"

def addDefaultInstance [Monad m] [MonadEnv m] [MonadLiftT IO m] (declName : Name) : m Unit := do
  let env ← getEnv
  let env ← Meta.addDefaultInstanceImp env declName
  setEnv env

builtin_initialize
  registerBuiltinAttribute {
    name  := `defaultInstance,
    descr := "type class default instance",
    add   := fun declName args persistent => do
      if args.hasArgs then throwError "invalid attribute 'defaultInstance', unexpected argument"
      unless persistent do throwError "invalid attribute 'defaultInstance', must be persistent"
      addDefaultInstance declName
  }

def getDefaultInstances [Monad m] [MonadEnv m] (className : Name) : m (List Name) :=
  return defaultInstanceExtension.getState (← getEnv) |>.defaultInstances.find? className |>.getD []

end Lean.Meta
