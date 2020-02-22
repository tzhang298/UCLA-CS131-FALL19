type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

(*1: convert_grammar*)
let rec convert_rules result rules  = match rules with
	| [] -> []
	| head :: rest ->
    if fst head = result then (snd head)::(convert_rules result rest)
    else convert_rules result rest;;

let convert_grammar gram1 = match gram1 with
  |(start_sym, rules) -> (start_sym, (fun x -> convert_rules x rules))


(*2: parse tree *)
let rec convert_to_list tree = match tree with
    []->[]
    | head::rest -> match head with
        |Leaf leaf -> leaf :: convert_to_list (rest)
        |Node (nonterminal, subtree) -> convert_to_list (subtree)@ convert_to_list(rest);;

let parse_tree_leaves tree = convert_to_list [tree];;


(*3 make_matcher gram: returns a matcher for the grammar gram.
 When applied to an acceptor accept and a fragment frag, the matcher must try
 the grammar rules in order and return the result of calling accept on the
 suffix corresponding to the first acceptable matching prefix of frag; this is
 not necessarily the shortest or the longest acceptable match. A match is
 considered to be acceptable if accept succeeds when given the suffix fragment
 that immediately follows the matching prefix. When this happens, the matcher
 returns whatever the acceptor returned. If no acceptable match is found,
 the matcher returns None.*)

let empty accept frag = accept frag;;
let nothing accept frag = None;;

let rec matcher prod_fun start_sym = function
  [] -> nothing
  | rule_head::rule_rest ->
    fun accept frag ->
      let match_head = iterate_rules prod_fun rule_head accept frag in
      let match_rest = matcher prod_fun start_sym rule_rest in
      match match_head with
        | None -> match_rest accept frag
        | _ -> match_head
and iterate_rules prod_fun = function
 | [] -> empty
 | (T terminal)::rule_rest ->
     (fun accept -> function
     | [] -> None
     | frag_head::frag_rest ->
       if frag_head = terminal then iterate_rules prod_fun rule_rest accept frag_rest
       else None)
 | (N nonterminal)::rule_rest ->
   let rules = prod_fun nonterminal in
   fun accept frag ->
     let nextaccept = iterate_rules prod_fun rule_rest accept
     in matcher prod_fun nonterminal rules nextaccept frag ;;


let make_matcher gram =
 let rules = (snd gram) (fst gram) in
 fun accept frag -> matcher (snd gram) (fst gram) rules accept frag;;

(*4 make_parser gram: returns a parser for the grammar gram.
 When applied to a fragment frag, the parser returns an optional parse tree.
 If frag cannot be parsed entirely (that is, from beginning to end), the parser
 returns None. Otherwise, it returns Some tree where tree is the parse tree
 corresponding to the input fragment. Your parser should try grammar rules in
 the same order as make_matcher.*)

let rec iterate_nts grammar rules acceptor frag = match rules with
| [] -> None
| head::rest -> (match check_rules grammar head acceptor frag with
    | None -> iterate_nts grammar rest acceptor frag
    | Some x -> Some (head::x))
and check_rules grammar rules acceptor frag = match rules with
| [] -> acceptor frag
| _ -> (match frag with
   | [] -> None
   | head::rest -> (match rules with
        |[] -> None
        |(T terminal)::remain -> if head = terminal then (check_rules grammar remain acceptor rest)
                                 else None
        |(N nonterminal)::remain -> (iterate_nts grammar (grammar nonterminal)
                              (check_rules grammar remain acceptor) frag)));;


let rec throughtree root rules =
match root with
| [] -> (rules, [])
| head::rest -> (match (throughleaf head rules) with
    | (a,b) -> (match throughtree rest a with
        | (c,d) -> (c, b::d)))
and throughleaf root rules =
match root with
| (T current) -> (match rules with
    | [] -> ([], Leaf current)
    | head::rest -> (head::rest, Leaf current))
    | (N current) -> (match rules with
        | [] -> ([], Node (current, []))
        | head::rest -> (match throughtree head rest with
            | (a,b) -> (a, Node (current, b))));;

let empty suffix = match suffix with
| [] -> Some []
| _ -> None ;;

let make_parser gram = match gram with
| (start_sym, rules) -> fun frag -> match (iterate_nts rules (rules start_sym) empty frag) with
| Some [] -> None
| None -> None
| Some x -> (match throughtree [N start_sym] x with
    | (_,y) -> (match y with
        | [] -> None
      	| head::rest -> Some head));;
