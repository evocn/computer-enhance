// 00
// Instruction Decoding on the 8086
// April 2025

/*
Registers have actual physical space on the 8086.

mov Ax, Bx
- How does the CPU decode this instruction?

mov instruction:
8 bits     | 8 bits     |
100010 d w | mod reg rm |
xxxxxx x x | xx xxx xxx |

d
- 0 = Instruction source is specified by the REG field.
- 1 = Instruction destination is specified by the REG field.

w (wide)
- 0 = 8 bits  (byte)
- 1 = 16 bits (word)

reg (register)
- Encodes a register.

r / m (register / memory)
- Encodes either a register or memory.

==========
Registers:

mov AL, BL
- Encodes just the low bits of the registers

mov AH, BH
- Encodes just the high bits of the registers

REG bits:

REG w=0 w=1
000 AL  AX
001 CL  CX
010 DL  DX
011 BL  BX
100 AH  SP
101 CH  BP
110 DH  SI
111 BH  DI

==========
Modes:

MOD bits:
Tells you if it is a memory operation or a register operation.
- 00 = Memory mode. No displacement follows. (Except for when R/M = 110, then 16-bit displacement follows.) @TODO: Why?
- 01 = Memory mode.  8-bit displacement follows.
- 10 = Memory mode. 16-bit displacement follows.
- 11 = Register mode. No displacement.

*/

// Assignment:
// Decode a Mov instruction from 8086 binary.
// - Read d and w bits.

#import "Basic";
#import "File";

INSTRUCTION_SIZE :: 16;


main :: () {
    context.print_style.default_format_int = .{base = 2};

    test_cases :: string.[
        //"listing_0037_single_register_mov",
        "listing_0038_many_register_mov",
    ];

    for test_case : test_cases {
        binary, success := read_entire_file(test_case);
        assert(success, "failed to open file %\n", test_case);

        instruction_count := (binary.count * 8) / INSTRUCTION_SIZE;
        instruction_pointer : *u16 = cast(*u16)binary.data;
        instruction_index : int;
        assembly_instructions : [..] string;
        while (instruction_index < instruction_count) {
            assembly := decode_binary_instruction(instruction_pointer[instruction_index]);
            array_add(*assembly_instructions, assembly);

            instruction_index += 1;
        }

        builder : String_Builder;

        print_to_builder(*builder, "; %\n\n", test_case);
        append(*builder, "bits 16\n\n");

        for instruction : assembly_instructions {
            print_to_builder(*builder, "%\n", instruction);
        }

        assembly := builder_to_string(*builder);

        print("%\n", assembly);
    }
}

#run main();

decode_binary_instruction :: (binary : u16) -> assembly : string
{
    byte1 : u16 = ((binary & 0x00FF) >> 0);
    byte2 : u16 = ((binary & 0xFF00) >> 8);

    /*
    print("byte1: %\n", byte1);
    print("byte2: %\n", byte2);
    */

    // byte 1
    opcode, d, w : u16;
    {
        opcode = byte1 >> 2;
        assert(opcode == 34, "Opcode is not mov... %\n", opcode);

        d = byte1 & 2;
        w = byte1 & 1;
    }

    /*
    print("opcode: %\n", opcode);
    print("d: %\n", d);
    print("w: %\n", w);
    */

    // byte 2
    mod, reg, rm : u16;
    {
        mod = (byte2 & 192) >> 6; // 11000000
        reg = (byte2 &  56) >> 3; // 00111000
        rm  = (byte2 &   7) >> 0; // 00000111
    }

    /*
    print("mod: %\n", mod);
    print("reg: %\n", reg);
    print("r/m: %\n", rm);
    */

    assert(mod == 3, "We're only decoding register-to-register instructions this instruction's mode field is %\n", mod);

    r1, r2 : string;
    {
        r1 = register_encoding(rm,  w == 1);
        r2 = register_encoding(reg, w == 1);
    }

    assembly := tprint("mov %, %", r1, r2);

    return assembly;
}

register_encoding :: (bits: u16, wide_bit_set: bool) -> register_name: string {
    assert(bits < 8, "You passed an invalid 'bits' argument to the register encoding: %", bits);

    if wide_bit_set {
        if bits == {
            case 0; return "ax";
            case 1; return "cx";
            case 2; return "dx";
            case 3; return "bx";
            case 4; return "sp";
            case 5; return "bp";
            case 6; return "si";
            case 7; return "di";
        }
    }
    else {
        if bits == {
            case 0; return "al";
            case 1; return "cl";
            case 2; return "dl";
            case 3; return "bl";
            case 4; return "ah";
            case 5; return "ch";
            case 6; return "dh";
            case 7; return "bh";
        }
    }

    assert(false, "Shouldn't get here!\n");
    return "";
}

