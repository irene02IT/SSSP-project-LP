%%%% -*- Mode:Prolog -*-

%%%% sssp.pl
%%%%
%%%% Linguaggi di Programmazione Anno Accademico 2025-2026
%%%% Progetto febbraio 2026 (E2P)
%%%% "Single Source Shortest Paths"
%%%%
%%%% Autore:
%%%% Irene E.


:- dynamic graph/1.
:- dynamic vertex/2.
:- dynamic arc/4.

:- dynamic distance/3.
:- dynamic previous/3.
:- dynamic visited/2.

:- dynamic heap/2.
:- dynamic heap_entry/4.


%%%%------------------------------------------------------------------------%%%%
%%%%                        Grafi in Prolog                                 %%%%
%%%%------------------------------------------------------------------------%%%%



%%%% new_graph/1
%%%% new_graph(G)
%%%%
%%%% Ha successo sempre. Se il grafo G non e' ancora presente nella
%%%% base-dati, lo aggiunge tramite assert/1.
new_graph(G) :- graph(G), !.
new_graph(G) :- assert(graph(G)), !.



%%%% delete_graph/1
%%%% delete_graph(G)
%%%%
%%%% Elimina dalla base-dati il grafo G insieme a tutti i suoi
%%%% vertici e archi.
delete_graph(G) :-
    graph(G),
    retractall(graph(G)),
    retractall(vertex(G, _)),
    retractall(arc(G, _, _, _)), !.



%%%% new_vertex/2
%%%% new_vertex(G, V)
%%%%
%%%% Ha successo sempre. Se il vertice V non e' ancora presente
%%%% nel grafo G, lo aggiunge alla base-dati tramite assert/1.
new_vertex(G, V) :-
    vertex(G, V), !.

new_vertex(G, V) :-
    graph(G),
    assert(vertex(G, V)), !.



%%%% vertices/2
%%%% vertices(G, Vs)
%%%%
%%%% Vero quando Vs e' la lista di tutti i vertici del grafo G.
vertices(G, Vs) :-
    graph(G),
    findall(V, vertex(G, V), Vs), !.



%%%% graph_vertices/2
%%%% graph_vertices(G, Vs)
%%%%
%%%% Predicato ausiliario. Vero quando Vs e' la lista degli
%%%% identificatori dei vertici del grafo G. Utilizzato
%%%% internamente da dijkstra_sssp/2.
graph_vertices(G, Vs) :-
    graph(G),
    findall(V, vertex(G, V), Vs), !.



%%%% new_arc/3
%%%% new_arc(G, U, V)
%%%%
%%%% Variante di new_arc/4 con peso di default pari a 1.
new_arc(G, U, V) :-
    new_arc(G, U, V, 1), !.



%%%% new_arc/4
%%%% new_arc(G, U, V, Weight)
%%%%
%%%% Aggiunge alla base-dati l'arco da U a V con peso Weight nel
%%%% grafo G. Crea implicitamente U e V se non esistono. Se l'arco
%%%% esiste gia', lo sostituisce con il nuovo peso. Fallisce se
%%%% Weight < 0 o se il grafo non esiste.
new_arc(G, U, V, Weight) :-
    graph(G),
    Weight >= 0,
    new_vertex(G, U),
    new_vertex(G, V),
    ( retract(arc(G, U, V, _)) -> true ; true ),
    assert(arc(G, U, V, Weight)), !.



%%%% arcs/2
%%%% arcs(G, Es)
%%%%
%%%% Vero quando Es e' la lista di tutti gli archi del grafo G,
%%%% nella forma arc(G, U, V, Weight).
arcs(G, Es) :-
    graph(G),
    findall(arc(G, U, V, W), arc(G, U, V, W), Es), !.



%%%% neighbors/3
%%%% neighbors(G, V, Ns)
%%%%
%%%% Vero quando V e' un vertice di G e Ns e' la lista degli archi
%%%% arc(G, V, N, W) che partono da V verso i suoi vicini diretti.
neighbors(G, V, Ns) :-
    graph(G),
    vertex(G, V),
    findall(arc(G, V, U, W), arc(G, V, U, W), Ns), !.



%%%% list_graph/1
%%%% list_graph(G)
%%%%
%%%% Stampa sulla console tutti i vertici e tutti gli archi
%%%% del grafo G utilizzando listing/1.
list_graph(G) :-
    listing(vertex(G, _)),
    listing(arc(G, _, _, _)).



%%%% list_arcs/1
%%%% list_arcs(G)
%%%%
%%%% Stampa sulla console tutti gli archi del grafo G
%%%% utilizzando listing/1.
list_arcs(G) :-
    listing(arc(G, _, _, _)), !.



%%%% list_vertices/1
%%%% list_vertices(G)
%%%%
%%%% Stampa sulla console tutti i vertici del grafo G
%%%% utilizzando listing/1.
list_vertices(G) :-
    listing(vertex(G, _)), !.



%%%%------------------------------------------------------------------------%%%%
%%%%                        SSSP in Prolog                                  %%%%
%%%%------------------------------------------------------------------------%%%%



%%%% inf_leq/2
%%%% inf_leq(A, B)
%%%%
%%%% Predicato ausiliario per il confronto tra distanze.
%%%% Vero quando A =< B, trattando l'atomo inf come +infinito.
inf_leq(inf, inf) :- !.
inf_leq(_, inf) :- !.
inf_leq(inf, _) :- !, fail.
inf_leq(A, B) :- A =< B.



%%%% inf_lt/2
%%%% inf_lt(A, B)
%%%%
%%%% Predicato ausiliario per il confronto tra distanze.
%%%% Vero quando A < B, trattando l'atomo inf come +infinito.
inf_lt(_, inf) :- !.
inf_lt(inf, _) :- !, fail.
inf_lt(A, B) :- A < B.



%%%% inf_add/3
%%%% inf_add(A, B, C)
%%%%
%%%% Predicato ausiliario per la somma di distanze.
%%%% Unifica C con A + B, propagando inf quando almeno
%%%% uno degli addendi e' l'atomo inf.
inf_add(inf, _, inf) :- !.
inf_add(_, inf, inf) :- !.
inf_add(A, B, C) :- C is A + B.



%%%% change_distance/3
%%%% change_distance(G, V, NewDist)
%%%%
%%%% Ritira dalla base-dati tutte le istanze di distance(G, V, _)
%%%% e asserisce distance(G, V, NewDist).
change_distance(G, V, NewDist) :-
    graph(G),
    vertex(G, V),
    retractall(distance(G, V, _)),
    assert(distance(G, V, NewDist)), !.



%%%% change_previous/3
%%%% change_previous(G, V, U)
%%%%
%%%% Ritira dalla base-dati tutte le istanze di previous(G, V, _)
%%%% e asserisce previous(G, V, U).
change_previous(G, V, U) :-
    graph(G),
    vertex(G, V),
    retractall(previous(G, V, _)),
    assert(previous(G, V, U)), !.



%%%% dijkstra_sssp/2
%%%% dijkstra_sssp(G, Source)
%%%%
%%%% Risolve il problema SSSP sul grafo G a partire dal vertice
%%%% sorgente Source, applicando l'algoritmo di Dijkstra.
%%%% Al termine della sua esecuzione, la base-dati contiene i fatti
%%%% distance/3, previous/3 e visited/2 per ogni vertice di G.
dijkstra_sssp(G, Source) :-
    graph(G),
    vertex(G, Source),
    retractall(distance(G, _, _)),
    retractall(visited(G, _)),
    retractall(previous(G, _, _)),
    new_heap(G),
    graph_vertices(G, ListaV),
    initialize_single_source(G, Source, ListaV),
    dijkstra(G, ListaV),
    delete_heap(G).



%%%% dijkstra/2
%%%% dijkstra(G, Vs)
%%%%
%%%% Ciclo principale dell'algoritmo di Dijkstra. Ad ogni passo
%%%% estrae il vertice con distanza minima dallo heap, lo marca
%%%% come visitato e rilassa gli archi verso i suoi vicini.
dijkstra(_, []) :- !.

dijkstra(G, ListaV) :-
    head(G, K_Root, V_Root),
    delete(ListaV, V_Root, ListaV_Rimanente),
    extract(G, K_Root, V_Root),
    assert(visited(G, V_Root)),
    vertex_neighbors(G, V_Root, V_AdiacentNonVisit),
    passo_di_rilassamento(G, V_Root, V_AdiacentNonVisit),
    dijkstra(G, ListaV_Rimanente), !.



%%%% passo_di_rilassamento/3
%%%% passo_di_rilassamento(G, V, ListaT)
%%%%
%%%% Per ogni vertice T in ListaT, verifica se il cammino che
%%%% passa per V offre una distanza migliore rispetto a quella
%%%% corrente. In caso affermativo, aggiorna distance/3,
%%%% previous/3 e la chiave nello heap tramite modify_key/4.
passo_di_rilassamento(_, _, []) :- !.

passo_di_rilassamento(G, V, [T | Resto]) :-
    distance(G, V, V_Dist),
    distance(G, T, T_Dist),
    arc(G, V, T, Weight),
    inf_add(V_Dist, Weight, NewDist),
    inf_leq(T_Dist, NewDist), !,
    passo_di_rilassamento(G, V, Resto).

passo_di_rilassamento(G, V, [T | Resto]) :-
    distance(G, V, V_Dist),
    arc(G, V, T, Weight),
    inf_add(V_Dist, Weight, NewDist),
    change_distance(G, T, NewDist),
    change_previous(G, T, V),
    heap_entry(G, _, OldKey, T),
    modify_key(G, NewDist, OldKey, T),
    passo_di_rilassamento(G, V, Resto), !.



%%%% initialize_single_source/3
%%%% initialize_single_source(G, Source, ListaV)
%%%%
%%%% Fase di inizializzazione dell'algoritmo di Dijkstra.
%%%% Assegna distanza 0 alla sorgente Source e distanza inf
%%%% a tutti gli altri vertici, inserendo ciascuno nello heap
%%%% con la rispettiva chiave.
initialize_single_source(_, _, []) :- !.

initialize_single_source(G, Source, [Source | Resto]) :-
    assert(distance(G, Source, 0)),
    insert(G, 0, Source),
    initialize_single_source(G, Source, Resto), !.

initialize_single_source(G, Source, [T | Resto]) :-
    assert(distance(G, T, inf)),
    assert(previous(G, T, not_defined)),
    insert(G, inf, T),
    initialize_single_source(G, Source, Resto), !.



%%%% vertex_neighbors/3
%%%% vertex_neighbors(G, V, Ns)
%%%%
%%%% Vero quando Ns e' la lista dei vertici direttamente
%%%% raggiungibili da V nel grafo G che non sono ancora
%%%% stati visitati durante l'esecuzione di Dijkstra.
vertex_neighbors(G, V, V_AdiacentiNonVisi) :-
    findall(N, arc(G, V, N, _), ListaAdiacenza_V),
    findall(T, visited(G, T), ListaVerticiVisitati),
    remove(ListaAdiacenza_V, ListaVerticiVisitati, V_AdiacentiNonVisi).



%%%% remove/3
%%%% remove(List1, List2, Ris)
%%%%
%%%% Vero quando Ris e' la lista ottenuta rimuovendo da List1
%%%% tutti gli elementi che compaiono in List2.
remove(List1, [], List1) :- !.

remove(List1, [T | Resto], Ris) :-
    member(T, List1), !,
    delete(List1, T, List1_rid),
    remove(List1_rid, Resto, Ris).

remove(List1, [_ | Resto], Ris) :-
    remove(List1, Resto, Ris), !.



%%%% shortest_path/4
%%%% shortest_path(G, Source, V, Path)
%%%%
%%%% Vero quando Path e' la lista ordinata degli archi
%%%%   [arc(G, Source, N1, W1), arc(G, N1, N2, W2), ..., arc(G, NK, V, Wk)]
%%%% che costituisce il cammino minimo da Source a V nel grafo G.
%%%% Richiede che dijkstra_sssp/2 sia gia' stato eseguito con
%%%% sorgente Source. Gestisce il caso base Source = V restituendo
%%%% il cammino vuoto [].
shortest_path(G, Source, Source, []) :-
    graph(G),
    vertex(G, Source), !.

shortest_path(G, Source, V, Path) :-
    V \= Source,
    graph(G),
    vertex(G, Source),
    vertex(G, V),
    list_path(G, Source, V, Path), !.



%%%% list_path/4
%%%% list_path(G, Source, V, Path)
%%%%
%%%% Predicato ausiliario di shortest_path/4. Ricostruisce
%%%% ricorsivamente il cammino minimo da Source a V risalendo
%%%% la catena dei predecessori tramite previous/3.
list_path(G, Source, V, Path) :-
    previous(G, V, Source),
    arc(G, Source, V, Weight),
    Path = [arc(G, Source, V, Weight)], !.

list_path(G, Source, V, Path) :-
    previous(G, V, U),
    U \= not_defined,
    arc(G, U, V, Weight),
    list_path(G, Source, U, PathProvvisorio),
    append(PathProvvisorio, [arc(G, U, V, Weight)], Path), !.

list_path(_, Source, V, _) :-
    format("Non esiste un percorso da ~w a ~w.~n", [Source, V]), !,
    fail.



%%%%------------------------------------------------------------------------%%%%
%%%%                        MinHeap in Prolog                               %%%%
%%%%------------------------------------------------------------------------%%%%



%%%% new_heap/1
%%%% new_heap(H)
%%%%
%%%% Aggiunge un nuovo heap H vuoto alla base-dati, se non
%%%% e' gia' presente. La dimensione iniziale e' 0.
new_heap(H) :- heap(H, _), !.
new_heap(H) :- assert(heap(H, 0)), !.



%%%% new_heap/2
%%%% new_heap(H, S)
%%%%
%%%% Aggiunge un nuovo heap H con dimensione iniziale S
%%%% alla base-dati, se non e' gia' presente.
new_heap(H, S) :- heap(H, S), !.
new_heap(H, S) :- assert(heap(H, S)), !.



%%%% delete_heap/1
%%%% delete_heap(H)
%%%%
%%%% Rimuove dalla base-dati lo heap H e tutti i suoi
%%%% elementi heap_entry/4.
delete_heap(H) :-
    retract(heap(H, _)),
    retractall(heap_entry(H, _, _, _)), !.



%%%% heap_size/2
%%%% heap_size(H, S)
%%%%
%%%% Vero quando S e' il numero di elementi attualmente
%%%% contenuti nello heap H.
heap_size(H, S) :- heap(H, S).



%%%% empty/1
%%%% empty(H)
%%%%
%%%% Vero quando lo heap H non contiene alcun elemento.
empty(H) :- heap(H, 0).



%%%% not_empty/1
%%%% not_empty(H)
%%%%
%%%% Vero quando lo heap H contiene almeno un elemento.
not_empty(H) :- \+ empty(H).



%%%% head/3
%%%% head(H, K, V)
%%%%
%%%% Vero quando l'elemento in cima allo heap H (ossia quello
%%%% con chiave minima) ha chiave K e valore V.
head(H, K, V) :-
    heap_entry(H, 1, K, V).



%%%% insert/3
%%%% insert(H, K, V)
%%%%
%%%% Inserisce il valore V nello heap H con chiave K.
%%%% L'elemento viene aggiunto in fondo e poi fatto risalire
%%%% tramite bubble/2 per ripristinare la heap property.
insert(H, K, V) :-
    heap(H, S),
    NS is S + 1,
    retract(heap(H, S)),
    assert(heap(H, NS)),
    assert(heap_entry(H, NS, K, V)),
    bubble(H, NS), !.



%%%% list_heap/1
%%%% list_heap(H)
%%%%
%%%% Stampa sulla console lo stato interno dello heap H,
%%%% mostrando tutti i fatti heap_entry/4 tramite listing/1.
list_heap(H) :-
    listing(heap_entry(H, _, _, _)).



%%%% bubble/2
%%%% bubble(H, P)
%%%%
%%%% Risale nello heap a partire dalla posizione P, scambiando
%%%% il nodo corrente con il padre fintanto che la chiave del
%%%% padre e' strettamente maggiore. Garantisce la heap property
%%%% dopo un inserimento. Gestisce correttamente l'atomo inf.
bubble(_, 1) :- !.

bubble(H, P) :-
    heap_entry(H, P, K, _),
    P_padre is floor(P / 2),
    heap_entry(H, P_padre, K_padre, _),
    inf_leq(K_padre, K), !.

bubble(H, P) :-
    P_padre is floor(P / 2),
    scambio(H, P_padre, P),
    bubble(H, P_padre), !.



%%%% extract/3
%%%% extract(H, K, V)
%%%%
%%%% Rimuove dallo heap H l'elemento con chiave minima,
%%%% unificando K e V con la sua chiave e il suo valore.
%%%% Dopo la rimozione lo heap viene ristrutturato tramite
%%%% min_heapify/2 per ripristinare la heap property.
extract(H, _, _) :-
    empty(H), !.

extract(H, K, V) :-
    heap(H, 1),
    retract(heap(H, 1)),
    assert(heap(H, 0)),
    retract(heap_entry(H, 1, K, V)), !.

extract(H, K, V) :-
    heap_entry(H, 1, K, V),
    heap_size(H, S),
    NS is S - 1,
    retract(heap(H, S)),
    assert(heap(H, NS)),
    retract(heap_entry(H, 1, K, V)),
    retract(heap_entry(H, S, K_ultimo, V_ultimo)),
    assert(heap_entry(H, 1, K_ultimo, V_ultimo)),
    min_heapify(H, 1), !.



%%%% min_heapify/2
%%%% min_heapify(H, P)
%%%%
%%%% Fa scendere il nodo in posizione P nello heap H,
%%%% scambiandolo con il figlio di chiave minima fintanto che
%%%% la heap property non e' soddisfatta. Gestisce inf.
min_heapify(H, P) :-
    heap_size(H, S),
    P_sx is P * 2,
    P_sx > S, !.

min_heapify(H, P) :-
    heap_size(H, S),
    P_sx is P * 2,
    P_dx is P_sx + 1,
    heap_entry(H, P, K, _),
    ( P_dx > S ->
        P_min = P_sx
    ;
        heap_entry(H, P_sx, K_sx, _),
        heap_entry(H, P_dx, K_dx, _),
        ( inf_leq(K_sx, K_dx) -> P_min = P_sx ; P_min = P_dx )
    ),
    heap_entry(H, P_min, K_min, _),
    ( inf_lt(K_min, K) ->
        scambio(H, P, P_min),
        min_heapify(H, P_min)
    ;
        true
    ), !.



%%%% scambio/3
%%%% scambio(H, P1, P2)
%%%%
%%%% Scambia i nodi nelle posizioni P1 e P2 dello heap H,
%%%% aggiornando i corrispondenti fatti heap_entry/4.
scambio(H, P1, P2) :-
    retract(heap_entry(H, P1, K1, V1)),
    retract(heap_entry(H, P2, K2, V2)),
    assert(heap_entry(H, P1, K2, V2)),
    assert(heap_entry(H, P2, K1, V1)).



%%%% modify_key/4
%%%% modify_key(H, NewKey, OldKey, V)
%%%%
%%%% Sostituisce la chiave OldKey associata al valore V con
%%%% la nuova chiave NewKey, quindi ristruttura lo heap tramite
%%%% bubble/2 e min_heapify/2 per ripristinare la heap property.
%%%% Il retract unifica direttamente la posizione P, garantendo
%%%% che P sia istanziato prima dell'assert e dei richiami successivi.
modify_key(H, NewKey, OldKey, V) :-
    heap(H, _),
    retract(heap_entry(H, P, OldKey, V)),
    assert(heap_entry(H, P, NewKey, V)),
    bubble(H, P),
    min_heapify(H, P), !.



%%%%------------------------------------------------------------------------%%%%
%%%%                        Test                                            %%%%
%%%%------------------------------------------------------------------------%%%%



%%%% test/1
%%%% test(G)
%%%%
%%%% Costruisce il grafo di esempio con 6 vertici e 10 archi,
%%%% tratto dal testo del progetto.
test(G) :-
    new_graph(G),
    new_vertex(G, r),
    new_vertex(G, s),
    new_vertex(G, t),
    new_vertex(G, x),
    new_vertex(G, y),
    new_vertex(G, z),
    new_arc(G, r, s, 5),
    new_arc(G, r, t, 3),
    new_arc(G, s, t, 2),
    new_arc(G, s, x, 3),
    new_arc(G, t, x, 7),
    new_arc(G, t, y, 4),
    new_arc(G, t, z, 8),
    new_arc(G, x, y, 1),
    new_arc(G, x, z, 2),
    new_arc(G, y, x, 10).

%%%% end of file sssp.pl
