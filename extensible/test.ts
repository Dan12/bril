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
  f1:number;
}

interface B {
  op: "D" | "E";
  f2:boolean;
}

interface C {
  op: "A" | "E";
  f3:string;
}

interface notA<X> {
  op: Exclude<X,A["op"]>
}

function test<Y,X extends notA<Y>>(instr: A | X, f: (x:X) => number) {
  switch(instr.op) {
    case "A" : {
      return instr.f1;  
    }
    case "B" : {
      return instr.f1;
    }
    case "C" : {
      return instr.f1;
    }
    default: {
      return f(instr);
    }
  }
}