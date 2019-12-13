// type Ident = string;

// type Type = "int" | "bool";

// type TypeExt = Type | "ptr";

// interface EffectOperation {
//     op: "br" | "jmp" | "print" | "ret";
//     args: Ident[];
//   }

//   interface ExtEffectOperation {
//     op: EffectOperation["op"] | "store" | "free"
//     args: Ident[];
//   }

interface A {
  op: "A" | "B" | "C";
  args: string[];
  f1:number;
}

interface B {
  op: "D" | "E";
  args: string[];
  f2:boolean;
}

interface C {
  op: "C" | "E";
  args: string[];
  f3:string;
}

interface Common {
  op: any;
}

// type A = "A" | "B" | "C";
// type B = "D" | "E";
// type C = "C" | "E";

function test<X extends Common>(op: A | Exclude<X,A>) {
  switch(op.op) {
    case "A" : {
      return true;
    }
  }
}