#!/usr/bin/env node
// -*-typescript-*-

import * as bril from '../bril-ts/bril';
import * as fs from 'fs';
import * as basicBlocks from './basicBlocks'

let main = function() {
    // Get the TypeScript filename.
    let filename = process.argv[2];
    if (!filename) {
        console.error(`usage: ${process.argv[1]} src.ts`)
        process.exit(1);
    }

    let content = fs.readFileSync(filename).toString();
    let program = JSON.parse(content) as bril.Program;
    // TODO generalize for more than 1 function
    let bbs = basicBlocks.formblocks(program.functions[0].instrs);
    let [cfg, entryLabel] = basicBlocks.buildCfg(bbs);
    console.log(cfg);
    console.log(entryLabel);
}

// Make unhandled promise rejections terminate.
process.on('unhandledRejection', e => { throw e });

main();
