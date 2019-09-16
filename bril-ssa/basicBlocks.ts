import * as bril from '../bril-ts/bril';

let terminators = ['br', 'jmp', 'ret']

export function formblocks(insns: (bril.Instruction | bril.Label)[]) {
    let blocks = [];
    let curBlock: (bril.Instruction | bril.Label)[] = [];

    for (let insn of insns) {
        // it is a label
        if ('label' in insn) {
            if (curBlock.length !== 0) {
                blocks.push(curBlock);
            }
            curBlock = [insn];
        } else if ('op' in insn) {
            curBlock.push(insn);
            // terminators
            if (terminators.indexOf(insn.op) !== -1) {
                blocks.push(curBlock);
                curBlock = [];
            }
        }
    }

    if (curBlock.length !== 0) {
        blocks.push(curBlock);
    }
    return blocks
}

export function buildCfg(blocks: (bril.Instruction | bril.Label)[][]) {
    let cfg: { [label: string]: { insns: (bril.Instruction | bril.Label)[]; outgoingEdges: string[] } } = {};
    let firstLabeled = false;
    let entryLabel: null | string = null;
    let prevLabel: null | string = null;
    for (let block of blocks) {
        if (block.length === 0) {
            throw new Error('Each basic block must contain at least 1 instruction');
        }
        let firstInsn = block[0];
        let lastInsn = block[block.length - 1];
        let label: string;
        if (!firstLabeled) {
            if ('label' in firstInsn) {
                entryLabel = firstInsn.label;
            } else {
                entryLabel = 'entry';
            }
            label = entryLabel;
            firstLabeled = true;
        } else {
            if ('label' in firstInsn) {
                label = firstInsn.label;
            } else {
                throw new Error('Each basic block must start with a label');
            }
        }

        if (prevLabel !== null) {
            cfg[prevLabel].outgoingEdges.push(label);
        }
        prevLabel = null;

        cfg[label] = {
            insns: block, outgoingEdges: []
        };

        if ('op' in lastInsn) {
            if (lastInsn.op === 'jmp') {
                cfg[label].outgoingEdges.push(lastInsn.args[0])
            } else if (lastInsn.op === 'br') {
                cfg[label].outgoingEdges.push(lastInsn.args[1])
                cfg[label].outgoingEdges.push(lastInsn.args[2])
            } else if (lastInsn.op !== 'ret') {
                prevLabel = label
            }
        } else {
            throw new Error('Each basic block must end with an operation')
        }
    }
    return [cfg, entryLabel]
}
