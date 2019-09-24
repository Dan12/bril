let a = 32;
let b = 12;
for (let c = 0; c < 10; c = c) {
    if (a > b) {
        for (let i = b; i < a; i = i + 1) {
            console.log(a-b*c + i/4);
        }
        b = a;
    } else if (a == b) {
        for (let c = 0; c < 9; c = c + 1) {
            console.log(c / 2);
        }
        c = 5;
        b = a + 1;
    } else {
        for (let b = 0; b < a; b = b + 1) {
            console.log(c*b);
        }
        c = 10;
    }
}
