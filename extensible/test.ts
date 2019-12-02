type Ident = string;

type Type = "int" | "bool";

type TypeExt = Type | "ptr";

interface EffectOperation {
    op: "br" | "jmp" | "print" | "ret";
    args: Ident[];
  }

  interface ExtEffectOperation {
    op: EffectOperation["op"] | "store" | "free"
    args: Ident[];
  }