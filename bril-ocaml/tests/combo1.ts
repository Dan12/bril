let a = 32;
let b = 12;
for (let c = 0; c < 10; c = c) {
    if (a > b) {
        for (let i = b; i < a; b = b + 1) {
            console.log(a-b*c);
        }
        b = a;
    } else if (a == b) {
        for (let c = 0; c < 9; c = c + 1) {
            console.log(c / 2);
        }
        c = 5;
    } else {
        for (let b = 0; b < a; b = b + 1) {
            console.log(c*b);
        }
        c = 10;
    }
}
