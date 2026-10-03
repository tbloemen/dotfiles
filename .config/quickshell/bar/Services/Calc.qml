pragma Singleton
import QtQuick
import Quickshell

// The launcher's calculator: a small recursive-descent parser for what you'd
// type into a search field -- + - * / % ^ (power), parentheses, unary minus,
// pi / e, and sqrt, sin, cos, tan, asin, acos, atan, ln, log (base 10), abs,
// round, floor, ceil, exp. A comma also works as the decimal point.
// Deliberately no eval(): only these tokens are understood.
Singleton {
    id: root

    readonly property var functions: ({
            sqrt: Math.sqrt,
            sin: Math.sin,
            cos: Math.cos,
            tan: Math.tan,
            asin: Math.asin,
            acos: Math.acos,
            atan: Math.atan,
            ln: Math.log,
            log: Math.log10,
            abs: Math.abs,
            round: Math.round,
            floor: Math.floor,
            ceil: Math.ceil,
            exp: Math.exp
        })
    readonly property var constants: ({
            pi: Math.PI,
            e: Math.E
        })

    // {expr, text} for a query that is a calculation, else null. A bare
    // number or a word isn't one: it needs a digit and an operator or
    // function, so app searches never turn into sums.
    function evaluate(query: string): var {
        const expr = query.trim().replace(/^=\s*/, "");
        if (!/\d/.test(expr) || !/[-+*\/%^(]|[a-z]/i.test(expr.replace(/^-?[\d.,]+(e[-+]?\d+)?$/i, "")))
            return null;
        let value;
        try {
            value = parse(tokenize(expr.replace(/,/g, ".")));
        } catch (e) {
            return null;
        }
        if (typeof value !== "number" || !isFinite(value))
            return null;
        return {
            expr: expr,
            text: format(value)
        };
    }

    function format(v: real): string {
        // 12 significant digits hides float noise (0.1 + 0.2).
        const n = Number(v.toPrecision(12));
        return Math.abs(n) >= 1e15 || (n !== 0 && Math.abs(n) < 1e-6) ? n.toExponential() : String(n);
    }

    function tokenize(s: string): var {
        const tokens = [];
        const re = /\s*(?:(\d+\.?\d*(?:e[-+]?\d+)?|\.\d+(?:e[-+]?\d+)?)|([a-z]+)|(\*\*|[-+*\/%^()]))/iy;
        let m;
        while (re.lastIndex < s.length && (m = re.exec(s)) !== null) {
            if (m[1] !== undefined)
                tokens.push({
                    t: "num",
                    v: parseFloat(m[1])
                });
            else if (m[2] !== undefined)
                tokens.push({
                    t: "id",
                    v: m[2].toLowerCase()
                });
            else
                tokens.push({
                    t: "op",
                    v: m[3] === "**" ? "^" : m[3]
                });
        }
        if (re.lastIndex < s.replace(/\s+$/, "").length)
            throw new Error("unexpected input");
        return tokens;
    }

    // expr   := term (("+" | "-") term)*
    // term   := unary (("*" | "/" | "%") unary)*
    // unary  := "-" unary | "+" unary | power
    // power  := atom ("^" unary)?          (right-associative)
    // atom   := number | constant | func atom | "(" expr ")"
    function parse(tokens: var): real {
        let i = 0;
        const peek = () => tokens[i];
        const isOp = v => peek() !== undefined && peek().t === "op" && peek().v === v;

        function expr() {
            let v = term();
            while (isOp("+") || isOp("-"))
                v = tokens[i++].v === "+" ? v + term() : v - term();
            return v;
        }
        function term() {
            let v = unary();
            while (isOp("*") || isOp("/") || isOp("%")) {
                const op = tokens[i++].v;
                const r = unary();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }
        function unary() {
            if (isOp("-")) {
                i++;
                return -unary();
            }
            if (isOp("+")) {
                i++;
                return unary();
            }
            return power();
        }
        function power() {
            const base = atom();
            if (isOp("^")) {
                i++;
                return Math.pow(base, unary());
            }
            return base;
        }
        function atom() {
            const tok = tokens[i++];
            if (tok === undefined)
                throw new Error("unexpected end");
            if (tok.t === "num")
                return tok.v;
            if (tok.t === "id") {
                if (tok.v in root.constants)
                    return root.constants[tok.v];
                if (tok.v in root.functions)
                    return root.functions[tok.v](atom());
                throw new Error("unknown name");
            }
            if (tok.v === "(") {
                const v = expr();
                if (!isOp(")"))
                    throw new Error("missing )");
                i++;
                return v;
            }
            throw new Error("unexpected token");
        }

        const v = expr();
        if (i !== tokens.length)
            throw new Error("trailing input");
        return v;
    }
}
