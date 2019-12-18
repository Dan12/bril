import { Actions } from "./brili_func";

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

export interface BaseAction {
  type: string;
}

type ToLabel = { "type": "label", "label": Ident };
export function jmpTo(label: Ident): ToLabel {
  return {"type": "label", "label": label};
}
type End = { "type": "end" };
type Next = { "type": "next" };
export type Action = ToLabel | Next | End;
export let NEXT: Next = { "type": "next" };
export let END: End = { "type": "end" };

export const actionTypes = ["end", "next", "label"] as const;
// This implements a type equality check for the above array, providing some static safety
type CheckLE = (typeof actionTypes)[number] extends (Action["type"]) ? any : never;
type CheckGE = (Action["type"]) extends (typeof actionTypes)[number] ? any : never;
let _: [CheckLE, CheckGE] = [0, 0];