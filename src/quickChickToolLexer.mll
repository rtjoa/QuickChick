{
open Lexing
open QuickChickToolParser
open QuickChickToolTypes

(* Function to increase line count in lexbuf *)
let line_incs s lexbuf =
(*  Printf.printf "Read: %s\n" s; *)
  let splits = Str.split_delim (Str.regexp "\n") s in 
  let pos = lexbuf.Lexing.lex_curr_p in
(* Printf.printf "Was in line %d, position %d\n" pos.pos_lnum (pos.pos_cnum - pos.pos_bol); *)
  lexbuf.Lexing.lex_curr_p <- {
    pos with 
      Lexing.pos_lnum = pos.Lexing.pos_lnum + (List.length splits - 1);
      Lexing.pos_bol = if List.length splits > 1 then pos.Lexing.pos_cnum - (String.length (List.hd (List.rev splits))) else pos.Lexing.pos_bol
  }
}

let white    = [' ' '\t' '\r' '\n']
let nonwhite = [^ ' ' '\t' '\r' '\n']

(* Main Parsing match *)
rule lexer = parse
    
  | (white* "(*!" white* "Section" as s)    { line_incs s lexbuf; T_StartSection s }
  | (white* "(*!" white* "extends" as s)    { line_incs s lexbuf; T_Extends s }
  | (white* "(*!" white* "QuickChick" as s) { line_incs s lexbuf; T_StartQuickChick s }

  | (white* "(*!" white* "*)" as s)         { line_incs s lexbuf; T_StartMutants s }
  | (white* "(*!" as s)                     { line_incs s lexbuf; T_StartMutant s }
  | (white* "(*"  as s)                     { line_incs s lexbuf; T_StartComment s }

  | (white* "*)" as s)                      { line_incs s lexbuf; T_EndComment s }

  | (white* as s) (nonwhite as c)           { line_incs (s^(String.make 1 c)) lexbuf; T_Char (s^(String.make 1 c)) }
  | (white* as s) eof                       { line_incs s lexbuf; T_Eof s }



