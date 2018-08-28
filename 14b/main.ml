open Batteries

module KnotHash = struct
  let range n =
    let arr = Array.make n 0 in
    for i = 0 to n - 1 do arr.(i) <- i done ;
    arr

  let loop_copy src start len =
    let dst = Array.make len 0 in
    let src_len = Array.length src in
    let dst_i = ref 0 in
    (* Copy to the end of src *)
    for src_i = start to min src_len (start + len) - 1 do
      dst.(!dst_i) <- src.(src_i) ;
      incr dst_i
    done ;
    (* Copy any overflow starting from the beginning of src *)
    let overflow = len - (src_len - start) in
    for src_i = 0 to overflow - 1 do
      dst.(!dst_i) <- src.(src_i) ;
      incr dst_i
    done ;
    dst

  (* Write all of src into dst, starting at dst.(start), and looping to the
   * beginning of src if necessary
   *)
  let loop_blit src dst start =
    let src_len = Array.length src in
    let dst_len = Array.length dst in
    let src_i = ref 0 in
    (* Write to the end of dst *)
    for dst_i = start to min dst_len (start + src_len) - 1 do
      dst.(dst_i) <- src.(!src_i) ;
      incr src_i
    done ;
    (* Write any overflow starting from the begining of dst *)
    let overflow = src_len - (dst_len - start) in
    for dst_i = 0 to overflow - 1 do
      dst.(dst_i) <- src.(!src_i) ;
      incr src_i
    done ;
    ()

  let reverse arr =
    for i = 0 to (Array.length arr / 2) - 1 do
      let j = Array.length arr - i - 1 in
      let tmp = arr.(i) in
      arr.(i) <- arr.(j) ;
      arr.(j) <- tmp
    done ;
    ()

  let sparse_hash input =
    let arr = range 256 in
    let pos = ref 0 in
    let skip = ref 0 in
    for _ = 1 to 64 do
      Array.iter
        (fun len ->
          let span = loop_copy arr !pos len in
          reverse span ;
          loop_blit span arr !pos ;
          pos := (!pos + len + !skip) mod 256 ;
          incr skip )
        input
    done ;
    arr

  let rec partition arr partition_size =
    if Array.length arr = partition_size then [arr]
    else
      let halfsize = Array.length arr / 2 in
      let front = Array.sub arr 0 halfsize in
      let back = Array.sub arr halfsize halfsize in
      partition front partition_size @ partition back partition_size

  let multi_xor arr = Array.fold_left (fun acc v -> acc lxor v) 0 arr

  let dense_hash sparse_hash =
    partition sparse_hash 16 |> List.map multi_xor |> Array.of_list

  let hash input =
    let input = String.to_list input |> List.map Char.code in
    let suffix = [17; 31; 73; 47; 23] in
    let input = input @ suffix in
    sparse_hash (Array.of_list input) |> dense_hash
end

let make_row preimage =
  let hash = KnotHash.hash preimage in
  Array.fold_left
    (fun acc chunk ->
      let bits =
        Enum.fold
          (fun acc n ->
            let bit = chunk land (1 lsl n) > 0 in
            bit :: acc )
          [] (0 -- 7)
      in
      acc @ bits )
    [] hash
  |> Array.of_list

let make_grid input =
  Array.map
    (fun v -> Printf.sprintf "%s-%d" input v |> make_row)
    (Array.of_enum (0 -- 127))

let print_grid g =
  Array.iter
    (fun row ->
      Array.iter (fun v -> print_string (if v then "#" else ".")) row ;
      print_newline () )
    g

let merge_regions from into p2r r2p =
  if from = into then (p2r, r2p)
  else
    let from_points = Map.Int.find from r2p in
    let to_points = Map.Int.find into r2p in
    let r2p = Map.Int.remove from r2p in
    let r2p = Map.Int.add into (to_points @ from_points) r2p in
    let p2r =
      List.fold_left (fun acc p -> Map.String.add p into acc) p2r from_points
    in
    (p2r, r2p)

let point i j = string_of_int i ^ "-" ^ string_of_int j

let count_regions grid =
  (* point to region *)
  let p2r = ref Map.String.empty in
  (* region to list of points *)
  let r2p = ref Map.Int.empty in
  for i = 0 to Array.length grid - 1 do
    for j = 0 to Array.length grid - 1 do
      if (grid.(i)).(j) then (
        let r = (i * Array.length grid) + j in
        let p = point i j in
        p2r := Map.String.add p r !p2r ;
        r2p := Map.Int.add r [p] !r2p ;
        if i > 0 && (grid.(i - 1)).(j) then (
          let other = Map.String.find (point (i - 1) j) !p2r in
          let a, b = merge_regions r other !p2r !r2p in
          p2r := a ;
          r2p := b ) ;
        let r = Map.String.find p !p2r in
        if j > 0 && (grid.(i)).(j - 1) then (
          let other = Map.String.find (point i (j - 1)) !p2r in
          let a, b = merge_regions r other !p2r !r2p in
          p2r := a ;
          r2p := b ) )
    done
  done ;
  Map.Int.cardinal !r2p

let () =
  let input = "amgozmfv" in
  let grid = make_grid input in
  print_grid grid ;
  count_regions grid |> dump |> print_endline
