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

function isA(a:any): a is A {
  return 'op' in a && 'f1' in a
}

function test<X>(instr: A | X) {
  if (isA(instr)) {
    return instr.f1;
  } else {
    return 1;
  }
}

// interface C {
//   op: "A" | "E";
//   f3:string;
// }

// interface notA<X> {
//   op: Exclude<X,A["op"]>
// }

// function test<Y,X extends notA<Y>>(instr: A | X, f: (x:X) => number) {
//   switch(instr.op) {
//     case "A" : {
//       return instr.f1;  
//     }
//     case "B" : {
//       return instr.f1;
//     }
//     case "C" : {
//       return instr.f1;
//     }
//     default: {
//       return f(instr);
//     }
//   }
// }

// type A = {"a": string}
// type B = {"a": number}

// function t<X>(a: A | X, f: (x:X) => string): string {
//   if ('a' in a) {
//     return a.a;
//   } else {
//     return f (a);
//   }
// }

// let a : A = {"a": "hi"};
// let f = (x:B) => {
//   return x.a + " a string";
// }
// let tmpa = t(a, f);
// let b: B = {"a": 5};
// let tmpb = t(b, f);

// console.log(typeof tmpa)
// console.log(typeof tmpb)