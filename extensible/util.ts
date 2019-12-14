/**
 * Read all the data from stdin as a string.
 */
export function readStdin(): Promise<string> {
  return new Promise((resolve, reject) => {
    let chunks: string[] = [];
    process.stdin.on("data", function (chunk: string) {
      chunks.push(chunk);
    }).on("end", function () {
      resolve(chunks.join(""))
    }).setEncoding("utf8");
  });
}

export function unreachable(x: never): any {
  throw "impossible case reached";
}

export type Ident = string;

export interface BaseInstruction {
  op: string;
}

export interface Label {
  label: Ident;
}

export interface BaseFunction<I extends BaseInstruction> {
  name: Ident;
  instrs: (I | Label)[];
}

export interface BaseProgram<I extends BaseInstruction, F extends BaseFunction<I>> {
  functions: F[];
}