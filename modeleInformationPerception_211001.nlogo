breed [agri agris]
breed [noPol noPols]
breed [gov govs]
breed [water waters]

agri-own [typ K K-1 cK MBK W IFT alpha a_z a_d s_z s_d p_z p_d BI_d BI_z seuilBI ga gs gp dNeighB sN_d sN_z sB_d sB_z sT_d sT_z nw nwG oE aE aF eP f1 node-clustering-coefficient distance-from-other-agri info attEinit Cmaxi CnoI]

; typ : farmer's type, 1 for eco-friendly and 2 for economicus
; K : farming practice
; K-1 : farming practive in step t-1
; cK : duration of farming practice
; W : knowledge about farming practice
; IFT : treatment frequency index
; alpha : coefficient of transformation of TFI into a water pollutant

; a : attitude [0,1]
; s : subjective norm [0,1]
; p : perceived control [0,1]
; BI_d : intention for change to organic farming [0,1]
; BI_z : intention for change to conventionnal farming [0,1]
; seuilBI : threshold [0,1]
; ga, gs, gp : weighting coefficients of attitude, subjective norm and perceived control in the calculation of BI [0,1]

; sN : subjective norm from neighborhood
; sB : subjective norm from belonging group
; nw : network, list of 8 other farmers
; nwG : network create if the farmer participate at training

; oE : weight of importance of environment in attitude
; aF : financial aspect of attitude
; aE : environmental aspect of attitude
; eP : environmental perception

; f1 : 1 if farmer have already be in training


gov-own [MAE-list forma-list newMAE-list newForma-list]
; st1 and so on no used -> later in dynamic governance

links-own [rewired?]


globals[
  i
  l
  nb1
  nb2
  nbL
  nbH
  gostop
  vois1
  vois2
  vois3
  vois4
  vois5
  vois6
  vois7
  vois8
  listAgri
  itemListAgri
  R

  ;display
  totAtt_1ZD
  totSN_1ZD
  totPC_1ZD
  totAtt_1DZ
  totSN_1DZ
  totPC_1DZ
  totAtt_2ZD
  totSN_2ZD
  totPC_2ZD
  totAtt_2DZ
  totSN_2DZ
  totPC_2DZ
  totAtt_1ZZ
  totSN_1ZZ
  totPC_1ZZ
  totAtt_1DD
  totSN_1DD
  totPC_1DD
  totAtt_2ZZ
  totSN_2ZZ
  totPC_2ZZ
  totAtt_2DD
  totSN_2DD
  totPC_2DD
  cagriz_1
  cagriz_2
  cagrid_1
  cagrid_2
  I_type1
  I_type2

  ;data about farming practices
  donneesMBIFT
  list-MB
  list-IFT

  ;abour water
  Arr ; water incoming in system
  Dep ; water leavig the system
  C ; nitrate concentration
  C-1 ; concentration year t-1
  N ; quantity of nitrate in water
  N-1 ; quantity of nitrate in t-1
  Nagri ; number of farmers
  Qu ; total water quantity
  Pinit ; initial pollution
  Requi ; quantity of pollutant in water to enter in the system to be at state equilibrium

  ; about decision-making process
  Kagri
  MB
  MBd
  MBz
  W-1

  ;about gouvernance
  D ; organic farming
  Z ; conventional farming
  comp ;compensation
  F ; training
  costs
  j
  compt ; counter
  listFarmNW ; general list of farmers involved in training
  farmZ ; number of farmers who come back to practice Z with practice D over threshold
  farmStop ; number of farmers who come back to practice Z with practice D under threshold

  ; network
  clustering-coefficient
  infinity
  average-path-length
  S-smallworld
]


to load-file ; file loading with data on TFI
set list-MB list 600 900
set list-IFT list 0 3.5


  ;    set donneesMBIFT "/home/amelie.bourceret/Documents/modelesNetLogo/fichiersNetlogo/donneesMBIFT.txt"
   ; data : gross margin, tfi
;    ifelse (file-exists? donneesMBIFT)
;    [
;    file-open donneesMBIFT
;    while [not file-at-end?]
;    [
;    set list-MB file-read
;    set list-IFT file-read
;    ]
;     file-close
;    ]
;    [user-message (word "Error reading filename file – File doesn’t exist")]
end

to setup

  clear-all

  load-file ; downloading farming practices' data

  set D 0 ; 0 or D correspond to organic farming
  set Z 1 ; 1 or Z correspond to conventional farming
  set Qu Q ; water quantity in millions of liters
  set Dep ED ; water renewal in millions of liters
  set Arr ED ; water incoming in milliont of liters
  set Pinit 0 ; initial nitrate concentration
 ;set Cinit 0.75 * (80 - probaLow)
 ;set C 0.75 * (80 - probaLow) ; initial nitrate concentration in water
  set MBz ( item Z list-MB ) ; gross margin for Z
  set MBd ( item D list-MB) ; gross margin for D
  set infinity 10000000
  set R (G * ED / Q) / nbAgri
  set C Cinit

  set compt 0

  ; creation of 'nbAgri' farmers
  set nb1 0 ; to count the number of farmers in type 1
  set nb2 0 ; to count the number of farmers in type 2
  set nbL 0
  set nbH 0
  ask patches [
    set pcolor 67
    set compt compt + 1
    if (compt <= nbAgri ) [
      sprout-agri 1 [
        set xcor pxcor
        set ycor pycor
        initialize
        set shape "person"
      ]
    ]
  ]

  createNetwork ; to create farmers social networks
  createLinks ; display networklinks
  changeNW

  while [not do-calculations] [
    ask links [die]
    createNetwork ; to create farmers social networks
    createLinks ; display networklinks
    changeNW
  ]
  set S-smallworld (clustering-coefficient / 0.0771071875 ) / (average-path-length / 2.5383255366 )

  createGov ; to create governance

  create-water 1 [set hidden? true] ; to create watershed

  reset-ticks
  set gostop 0
  set listFarmNW (list -1) ; to create a list where all farmers entering the program are part of

end

to go
  if ((gAtt + gSN) > 100 ) [
    write ("kk")
    stop
  ]
  ask gov [majGov] ; in case of dynamic governance NOT USE
  ask agri [majK] ; farming practive updating
  affichage ; display

  ; two following lines concern a new training network
  ask agri [if ((K = D) and (not member? who listFarmNW)) [set listFarmNW lput who listFarmNW]] ; addition of farmer in general training network

  ask water [majC] ; update watershed

  ask gov [govCosts] ; update costs of governance

  tick

  ; all simulations are 20 steps simulations
  set gostop (gostop + 1)
  if (gostop > nbGo)
    [stop]
end

to init
  set nbAgri 80 ; randomly on patches, only 1 farmer by patch
  set %_type1 50 ; exatly 50% of farmers are type 1 and 50% are type 2 ;
  set formation true
  set mae true
  set niv_forma 0.5
  set niv_mae 300
  set dK 5
  set retour false
  set gAtt 66
  set gSN 34
  set gPCB 0.33333
  set e1 0.5
  set e2 0.1
  set Normal 0.5
  set ET 0.125
  set Cinit 50
  set farmZ 0
  set nbLow 0
  set ED 50
  set Q 200
end

to paramInit
  ; to collect information about initialization
  show (word "nbAgri : " nbAgri " %_type1 : "%_type1 " formation : " formation " niv_forma : " niv_forma " mae : " mae " niv_mae : " niv_mae " retour : " retour " dK : " dK " gAtt : " gAtt " gSN : " gSN " e1 : " e1 " e2 : " e2 " Normal : " Normal " ET : " ET)
end


;;;;;;;;; GOUVERNANCE ;;;;;;;;;;;;

to createGov ; in case of dynamic governance NOT USE
  create-gov 1[
    set hidden? true
    set color pink
    set xcor 1
    set ycor 1
    set MAE-list (list 350 400 400 400 400 345.5 348 378)
    set forma-list (list 0 0 0.2 0.4 0.5 0.2 0.4 0.5)
    set newMAE-list (list 350 350 350 350 350 350 350 350)
    set newForma-list (list 0 0 0 0 0 0 0 0 0)
  ]
end

to majGov ; in case of dynamic governance NOT USE

  ifelse (sc > 0) [
    ifelse (gostop >= 10)[
    set comp item (sc ) newMAE-list
    set F item (sc ) newForma-list
    ]
    [
      set comp item (sc ) MAE-list
      set F item (sc ) forma-list
    ]
  ][ifelse (gostop >= 10)[
    set comp niv_MAE ;niv_MAE2
    set F niv_forma ;niv_forma2
    ]
    [
      set comp niv_MAE
      set F niv_forma
    ]
  ]

end

to govCosts ; calculation of costs for governance
  set compt 0
  ask agri [if (K = 0) [set compt compt + 1 ]]
  set costs comp * compt
end


;;;;;;;;;;;;; FARMERS ;;;;;;;;;;;;;

to initialize ; initialization of farmers

  set K 1 ; all farmers are in conventional farming at beginning

  if (pop = "pop0")[
    set ga gAtt / 100
    set gs ( 100 - gAtt ) / 100
    set gp 0 ; 1 - ga - gs ;gPCBp
    ;set gs gSN
    ;set gp 1 / 3;ga (1 - gSN) / 2 ; gSN ;1 - ga - gp
    ;set ga 1 - gp - gs ;gPCB
    if ((ga + gs) > 1 ) [
      stop
  ]]
  if (pop = "pop1")[set ga 0.333333 set gp 0.333333 set gs 0.333333]
  if (pop = "pop2")[set ga 0.5 set gp 0.25 set gs 0.25]
  if (pop = "pop3")[set ga 0.25 set gp 0.5 set gs 0.25]
  if (pop = "pop4")[set ga 0.25 set gp 0.25 set gs 0.5]

;  set ga gAtt
;  set gp gPCB
;  set gs 1 - ga - gp
;  if ((ga + gp) > 1 ) [
;    stop
;  ]

  set f1 0 ; 1 if farmer have already be in training

  ; Distribution between type 1 and type 2
  ifelse  (nb1 >= (%_type1 / 100 * nbAgri ) )
      [set typ 2 set nb2 nb2 + 1]
      [ifelse (nb2 >= (nbAgri * (1 - %_type1 / 100)) )
        [set typ 1 set nb1 nb1 + 1]
        [ifelse (random-float 1 > 0.5 )
          [set typ 1 set nb1 nb1 + 1]
          [set typ 2 set nb2 nb2 + 1]
        ]
      ]

  ; Distribution between low-input and high-input practice
  ifelse  (nbL >= (nbLow) )
      [set K 1 set nbH nbH + 1]
      [ifelse (nbH >= (nbAgri - nbLow))
        [set K 0 set nbL nbL + 1]
        [ifelse (random-float 1 > 0.5 )
          [set K 0 set nbL nbL + 1]
          [set K 1 set nbH nbH + 1]
        ]
      ]

  set K-1 1
  set cK -1 ; duration of farming practice
  set MBK (item K list-MB)
  set W (list 0 1) ; at the beginning knowledge are full (1) for conventional farming and non-existent (0) for organic farming
  set IFT (item K list-ift)
  set alpha 240 / 280 / 100 ; initial coefficient of transformation of TFI into a water pollutant to have a stable situation where nitrate concentration is 60

  ; Initialisation of attributs of type 1
  if (typ = 1) [
    set oE e1
    set seuilBI random-normal Normal ET
    set color 62
  ]
  ; Initialisation of attributs of type 2
  if (typ = 2) [
    set oE e2
    set seuilBI random-normal Normal ET
    set color 14
  ]

  set info random 100

  set CnoI random-normal NCnoI ETCnoI

end

to createNetwork ; create social networks
  ask agri[
    let who0 -1
    set nw []
    ask [agri-at 1 0] of patch xcor ycor  [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
    ask [agri-at -1 0] of patch xcor ycor [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
    ask [agri-at 0 1] of patch xcor ycor  [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
    ask [agri-at 0 -1] of patch xcor ycor  [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
    ask [agri-at 1 -1] of patch xcor ycor  [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
    ask [agri-at -1 -1] of patch xcor ycor  [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
    ask [agri-at 1 1] of patch xcor ycor  [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
   ask [agri-at -1 1] of patch xcor ycor [ set who0 who ]
    if (who0 != -1 and not member? who0 nw ) [set nw lput who0 nw]
  ]

end

to createLinks ; display network links
ask agri
  [ let it 0
    let abc 0
    while [it < (length nw)][
      set abc item it nw
      create-links-with agri with [who = abc][set color green set rewired? false]
      set it it + 1
    ]
  ]

end

to changeNW
  let number-rewired 0
  ;let rewiring-probability 0.5
  let node1 0
  let node3 0
  ask links [
    ;; whether to rewire it or not?
    if (random-float 1) < rewiring-probability

    [
      ;; "a" remains the same
      ifelse ((random-float 1) < 0.5) [set node1 end1 set node3 end2] [set node1 end2 set node3 end1]
      ;; if "a" is not connected to everybody
      ;if [ count link-neighbors ] of node1 < (count agri - 1)
      ;[
      ;; find a node distinct from node1 and not already a neighbor of node1
      let node2 one-of agri with [ (self != node1) and (not link-neighbor? node1) ]
      ;; wire the new edge
      ask node1 [
        create-link-with node2 [ set color cyan  set rewired? true ]
        set nw lput [who] of node2 nw
        set nw remove-item position [who] of node3 nw nw
      ]
      ask node2[
        set nw lput [who] of node1 nw
      ]
      ask node3[
        set nw remove-item position [who] of node1 nw nw
      ]

      set number-rewired number-rewired + 1  ;; counter for number of rewirings
      set rewired? true
      ;]
      die
    ]
    ;; remove the old edge
;    if (rewired?)
;    [
;      die
;    ]
  ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clustering computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient
  ifelse all? agri [count link-neighbors <= 1]
  [
    ;; it is undefined
    ;; what should this be?
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask agri with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask agri with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] / ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count agri with [count link-neighbors > 1]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Path length computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Implements the Floyd Warshall algorithm for All Pairs Shortest Paths
;; It is a dynamic programming algorithm which builds bigger solutions
;; from the solutions of smaller subproblems using memoization that
;; is storing the results.
;; It keeps finding incrementally if there is shorter path through
;; the kth node.
;; Since it iterates over all turtles through k,
;; so at the end we get the shortest possible path for each i and j.

to find-path-lengths
  ;; reset the distance list
  ask agri
  [
    set distance-from-other-agri []
  ]

  set i 0
  set j 0
  set l 0
  let node1 one-of agri
  let node2 one-of agri
  let node-count count agri
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 one-of agri with [who = i]
      set node2 one-of agri with [who = j]
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [
          set distance-from-other-agri lput 0 distance-from-other-agri
        ]
      ]
      [
        ;; 1 from a node to it's neighbor
        ifelse [ link-neighbor? node1 ] of node2
        [
          ask node1 [
            set distance-from-other-agri lput 1 distance-from-other-agri
          ]
        ]
        ;; infinite to everyone else
        [
          ask node1 [
            set distance-from-other-agri lput infinity distance-from-other-agri
          ]
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  set i 0
  set j 0
  let dummy 0
  while [l < node-count]
  [
    set i 0
    while [i < node-count]
    [
      set j 0
      while [j < node-count]
      [
        ;; alternate path length through kth node
        set dummy ( (item l [distance-from-other-agri] of one-of agri with [who = i]) +
                    (item j [distance-from-other-agri] of one-of agri with [who = l]))
        ;; is the alternate path shorter?
        if dummy < (item j [distance-from-other-agri] of one-of agri with [who = i])
        [
          ask agri with [who = i] [
            set distance-from-other-agri replace-item j distance-from-other-agri dummy
          ]
        ]
        set j j + 1
      ]
      set i i + 1
    ]
    set l l + 1
  ]

end


to-report do-calculations

  ;; set up a variable so we can report if the network is disconnected
  let connected? true

  ;; find the path lengths in the network
  find-path-lengths

  let num-connected-pairs sum [length remove infinity (remove 0 distance-from-other-agri)] of agri

  ;; In a connected network on N nodes, we should have N(N-1) measurements of distances between pairs,
  ;; and none of those distances should be infinity.
  ;; If there were any "infinity" length paths between nodes, then the network is disconnected.
  ;; In that case, calculating the average-path-length doesn't really make sense.
  ifelse ( num-connected-pairs != (count agri * (count agri - 1) ))
  [
    set average-path-length infinity
    ;; report that the network is not connected
    set connected? false
  ]
  [
    set average-path-length (sum [sum distance-from-other-agri] of agri) / (num-connected-pairs)
  ]
  ;; find the clustering coefficient and add to the aggregate for all iterations
  find-clustering-coefficient

  ;; report whether the network is connected or not
  report connected?

end

to affichage ; display
  set totSN_1ZD 0
  set totAtt_1ZD 0
  set totPC_1ZD 0
  set totSN_1DZ 0
  set totAtt_1DZ 0
  set totPC_1DZ 0
  set totSN_2ZD 0
  set totAtt_2ZD 0
  set totPC_2ZD 0
  set totSN_2DZ 0
  set totAtt_2DZ 0
  set totPC_2DZ 0
  set totSN_1ZZ 0
  set totAtt_1ZZ 0
  set totPC_1ZZ 0
  set totSN_1DD 0
  set totAtt_1DD 0
  set totPC_1DD 0
  set totSN_2ZZ 0
  set totAtt_2ZZ 0
  set totPC_2ZZ 0
  set totSN_2DD 0
  set totAtt_2DD 0
  set totPC_2DD 0
  set cagriz_1 0
  set cagriz_2 0
  set cagrid_1 0
  set cagrid_2 0
  let Ityp1 0
  let Ityp2 0
  let typ1 0
  let typ2 0
  set I_type1 0
  set I_type2 0

  ; 2 types of farmers : 1 and 2
  ; which can be organic or conventional, so Z or D : 1Z, 1D, 2Z, 2D
  ; and have two intention. An intention to stay on there own practice and an intention to go the other practice : Z and D
  ; so 8 differente intentions exist : 1ZZ ; 1ZD ; 1DZ ;1DD ;2ZZ ; 2ZD ; 2DZ ;2DD
  ; understand 1ZD as the average calculation of intention of type 1 farmer that are in organic farming (D) to change to conventional farming (Z)

  ask agri with [k = 0 and typ = 1]  [
    set totAtt_1ZD ( a_z + totAtt_1ZD  )
    set totSN_1ZD ( s_z + totSN_1ZD )
    set totPC_1ZD ( p_z  + totPC_1ZD )
    set totAtt_1DD ( a_d + totAtt_1DD  )
    set totSN_1DD ( s_d + totSN_1DD )
    set totPC_1DD ( p_d  + totPC_1DD )
    set cagrid_1 cagrid_1 + 1
  ]
  ifelse (cagrid_1 != 0 ) [set totAtt_1ZD totAtt_1ZD / cagrid_1] [set totAtt_1ZD 0]
  ifelse (cagrid_1 != 0) [set totPC_1ZD totPC_1ZD / cagrid_1] [set totPC_1ZD 0]
  ifelse (cagrid_1 != 0 ) [set totSN_1ZD totSN_1ZD / cagrid_1] [set totSN_1ZD 0]
  ifelse (cagrid_1 != 0 ) [set totAtt_1DD totAtt_1DD / cagrid_1] [set totAtt_1DD 0]
  ifelse (cagrid_1 != 0) [set totPC_1DD totPC_1DD / cagrid_1] [set totPC_1DD 0]
  ifelse (cagrid_1 != 0 ) [set totSN_1DD totSN_1DD / cagrid_1] [set totSN_1DD 0]

  ask agri with [k = 1 and typ = 1] [
    set totAtt_1DZ ( a_d + totAtt_1DZ )
    set totSN_1DZ ( s_d + totSN_1DZ )
    set totPC_1DZ ( p_d  + totPC_1DZ )
    set totAtt_1ZZ ( a_z + totAtt_1ZZ )
    set totSN_1ZZ ( s_z + totSN_1ZZ )
    set totPC_1ZZ ( p_z  + totPC_1ZZ )
    set cagriz_1 cagriz_1 + 1
  ]
  ifelse (cagriz_1 != 0 ) [ set totAtt_1DZ totAtt_1DZ / cagriz_1] [set totAtt_1DZ 0]
  ifelse (cagriz_1 != 0) [ set totPC_1DZ totPC_1DZ / cagriz_1] [set totPC_1DZ 0]
  ifelse (cagriz_1 != 0 ) [ set totSN_1DZ totSN_1DZ / cagriz_1] [set totSN_1DZ 0]
  ifelse (cagriz_1 != 0 ) [ set totAtt_1ZZ totAtt_1ZZ / cagriz_1] [set totAtt_1ZZ 0]
  ifelse (cagriz_1 != 0) [ set totPC_1ZZ totPC_1ZZ / cagriz_1] [set totPC_1ZZ 0]
  ifelse (cagriz_1 != 0 ) [ set totSN_1ZZ totSN_1ZZ / cagriz_1] [set totSN_1ZZ 0]

  ask agri with [k = 0 and typ = 2]  [
    set totAtt_2ZD ( a_z + totAtt_2ZD  )
    set totSN_2ZD ( s_z + totSN_2ZD )
    set totPC_2ZD ( p_z  + totPC_2ZD )
    set totAtt_2DD ( a_d + totAtt_2DD  )
    set totSN_2DD ( s_d + totSN_2DD )
    set totPC_2DD ( p_d  + totPC_2DD )
    set cagrid_2 cagrid_2 + 1
  ]
  ifelse (cagrid_2 != 0 ) [set totAtt_2ZD totAtt_2ZD / cagrid_2] [set totAtt_2ZD 0]
  ifelse (cagrid_2 != 0 )[set totPC_2ZD totPC_2ZD / cagrid_2] [set totPC_2ZD 0]
  ifelse (cagrid_2 != 0 )  [set totSN_2ZD totSN_2ZD / cagrid_2] [set totSN_2ZD 0]
  ifelse (cagrid_2 != 0 ) [set totAtt_2DD totAtt_2DD / cagrid_2] [set totAtt_2DD 0]
  ifelse (cagrid_2 != 0 )[set totPC_2DD totPC_2DD / cagrid_2] [set totPC_2DD 0]
  ifelse (cagrid_2 != 0 )  [set totSN_2DD totSN_2DD / cagrid_2] [set totSN_2DD 0]

  ask agri with [k = 1 and typ = 2] [
    set totAtt_2DZ ( a_d + totAtt_2DZ )
    set totSN_2DZ ( s_d + totSN_2DZ )
    set totPC_2DZ ( p_d  + totPC_2DZ )
    set totAtt_2ZZ ( a_z + totAtt_2ZZ )
    set totSN_2ZZ ( s_z + totSN_2ZZ )
    set totPC_2ZZ ( p_z  + totPC_2ZZ )
    set cagriz_2 cagriz_2 + 1
  ]
    ifelse (cagriz_2 != 0 ) [ set totAtt_2DZ totAtt_2DZ / cagriz_2 ] [set totAtt_2DZ 0]
    ifelse (cagriz_2 != 0) [ set totPC_2DZ totPC_2DZ / cagriz_2 ] [set totPC_2DZ 0]
    ifelse (cagriz_2 != 0  ) [ set totSN_2DZ totSN_2DZ / cagriz_2 ] [set totSN_2DZ 0]
    ifelse (cagriz_2 != 0 ) [ set totAtt_2ZZ totAtt_2ZZ / cagriz_2 ] [set totAtt_2ZZ 0]
    ifelse (cagriz_2 != 0) [ set totPC_2ZZ totPC_2ZZ / cagriz_2 ] [set totPC_2ZZ 0]
    ifelse (cagriz_2 != 0  ) [ set totSN_2ZZ totSN_2ZZ / cagriz_2 ] [set totSN_2ZZ 0]

  ask agri with [typ = 1]
  [ set Ityp1 Ityp1 + BI_d set typ1 typ1 + 1
  ]
  ifelse (typ1 != 0) [set I_type1 Ityp1 / typ1][set I_type1 0]

  ask agri with [typ = 2]
  [ set Ityp2 Ityp2 + BI_d  set typ2 typ2 + 1
  ]
  ifelse (typ2 != 0) [set I_type2 Ityp2 / typ2][set I_type2 0]

end

to majK ; update farming practice

  set BI_z 0
  set BI_d 0
  calculBI_d
  calculBI_z

  ; Reminder : cK = -1 at initial step
  if (cK < 0 )[
    if (K != D)[
      if (BI_d >= seuilBI )[
        set K D
        set cK dK ; minimum duration in the program
        set pcolor 75
        set f1 1

        set MBK (item K list-MB)
        set W-1 W
        set W replace-item D W-1 p_d
        set IFT (item K list-ift)

        chgmtNW
      ]
    ]
  ]

  ; ck = 0 when the minimum stay in the program is reached
  if (cK = 0 )[
    ; if retour is true then it is possible for farmers to come back to conventional farming
    if (retour = true) [
      ; 3 types of returning could be implemented

      ; Standard version : Stay
      ; "stay" : if the intention to stay in organic farming is above the threshold so the farmer keep his farming practice, otherwise he takes the other practice if the intention to change is higher than the threshold
      ; if he is in conventional farming he changes to organic famring if the intention is higher than the threhold
        ifelse (K != D)[
          if (BI_d >= seuilBI)[
            set K D
            set cK dK
            set pcolor 75
            set f1 1

            set MBK (item K list-MB)
            set W-1 W
            set W replace-item D W-1 p_d
            set IFT (item K list-ift)

            chgmtNW
          ]
        ]
        [ if (BI_d < seuilBI )[
          ;if (BI_z >= seuilBI)[
            set K 1
            set cK 0
            set pcolor 14

            set MBK (item K list-MB)
            set IFT (item K list-ift)

            set farmZ farmZ + 1
          ;]
          ]
        ]
    ]
  ]

  set K-1 K ; update K-1
  if (cK > 0 ) [set cK (cK - 1)] ; update cK

end

to calculBI_d ; calculation of BI (behavioural intention) for the practice D (organic farming)
  calculA_d ; attitude
  calculS_d ; subjective norm
  calculP_d ; perceived control
  set BI_d (ga * a_d + gs * s_d + gp * p_d)
end

to calculBI_z ; calculation of BI (behavioural intention) for the practice Z (conventional farming)
  calculA_z ; attitude
  calculS_z ; subjective norm
  calculP_z ; perceived control
  set BI_z (ga * a_z + gs * s_z + gp * p_z)
end

to calculA_d ; calculation of attitude for the practice D (organic farming)
  set aF (MBd - MBz + comp) / (MBz - MBd)
  if (Cmaxi = 0) [set Cmaxi 1]
  if (qep = 0) [set qep 1]

  let Ct1 0
    ifelse (typ = Typ_eP_on AND info < %info_typ )[
        set  Ct1 C
      ]
      [ifelse (Typ_eP_on = 3)[
        set   Ct1 C
        ]
        [ifelse (Typ_eP_on = 4 AND info < %info)[
          set  Ct1 C
          ]
          [set Ct1 CnoI]
        ]
      ]
   set ae (Ct1 ^ qep) / (Ct1 ^ qep + alphep ^ qep)

  if (ae < 0) [set ae 0]
  if (ae > 1) [set ae 1]
  set a_d (aF * (1 - Oe) + Oe * ae)
end

to sauvcalcul_Ad
  ifelse (typ = Typ_eP_on AND info < %info_typ )[
    set ae ( (C ^ qep) / (C ^ qep + alphep ^ qep) )
  ]
  [ifelse (Typ_eP_on = 3)[
    set ae ( (C ^ qep) / (C ^ qep + alphep ^ qep) )
    ]
    [ifelse (Typ_eP_on = 4 AND info < %info)[
      set ae ( (C ^ qep) / (C ^ qep + alphep ^ qep) )
      ]
      [set ae attEinit]
    ]
  ]
end

to calculA_z ; calculation of attitude for the practice Z (conventional farming)
  set aF (MBz - MBd - comp) / (MBz - MBd)
  set a_z (aF * (1 - Oe))
end











to calculS_d ; calculation of subjective norm for the practice D (low-input)
  set sB_d 0

  ;;; STEP 2 : calculation of percentage of low-input farmers (D) in social network

  set j 0 ; count the number of farmers in social network
  set l 0 ; count the number of D farmers in social network
  foreach nw [
    who0 -> set who0 who0 ; who0 takes the value of each item of nw 1 by 1
    ask agri with [who = who0] [
      if (K-1 = D) [set l (l + 1)]
    ]
    set j j + 1
  ]
  ifelse (j > 0) [set sB_d l / j] [set sB_d 0]

  ;;; STEP 3 : calculation of percentage of low-input farmers (D) in training network
  ifelse (member? who listFarmNW)[

    set j 0 ; count the number of farmers in training network
    set l 0 ; count the number of D farmers in training network

    foreach listFarmNW[
      who0 -> set who0 who0 ; who0 takes the value of each item of nw 1 by 1
      if (who0 != -1 )
      [ask agri with [who = who0][
        if (K-1 = D) [set l (l + 1)]
        ]
        set j j + 1
      ]
    ]
    ifelse (j > 1) [set sT_d l / j][set sT_d 0]
  ]
  [ set sT_d 0 ]

  set s_d sB_d
end

to calculS_z ; calculation of subjective norm for the practice Z (conventional farming)
  set sB_z 0

  ;;; STEP 2 : calculation of percentage of organic farmers (D) in social network
  set j 0 ; count the number of farmers in social network
  set l 0 ; count the number of D farmers in social network
  foreach nw [
    who0 -> set who0 who0 ; who0 takes the value of each item of nw 1 by 1
    ask agri with [who = who0] [
      if (K-1  = Z) [set l (l + 1)]
    ]
    set j j + 1
  ]

  ifelse (j > 0) [set sB_z l / j] [set sB_z 0]


  ;;; STEP 3 : calculation of percentage of organic farmers (D) in training network
  ifelse (member? who listFarmNW)[

    set j 0 ; count the number of farmers in training network
    set l 0 ; count the number of D farmers in training network

    foreach listFarmNW[
      who0 -> set who0 who0 ; who0 takes the value of each item of nw 1 by 1
      if ((who0 != 0 ))
      [ask agri with [who = who0][
        if (K-1  = 1) [set l (l + 1)]
        ]
        set j j + 1
      ]
    ]
    ifelse (j > 1) [set sT_z l / j][set sT_z 0]
  ][
    set sT_z 0
  ]

end

to calculP_d ; calculation of perceived control for the practice D (organic farming)
  set i (item (D) W)
  ; if farming practice is not D/0/organic then if the farmer change to organic farming his perceived control will increase with the training (F) but only if it's the first time he is inlvolved in program (f1 != 0)
  if (K != 0 ) [
    set p_d (i + F * (1 - f1))
  ]
  if (p_d > 1) [set p_d 1]
end

to calculP_z ; calculation of perceived control for the practice Z (conventional farming)
  set p_z (item (Z) W)
end

to chgmtNW ; changement of network + under development
  set nwG listFarmNW
end


;;;;;;;;;;;; WATER ;;;;;;;;;;;;;

to majC ; update water nitrate concentration

  set Nagri 0
  if (ticks = 0) [set C Cinit set N (C * Qu )]
  set C-1 C
  set N-1 N
  ask agri [if (K = Z) [set Nagri (Nagri + R)] ]
  ;ask agri [set Nagri (Nagri + alpha * IFT)]
  set N (Pinit * Arr + N-1 - Dep * C-1 + Nagri * Q)
  set C (N / Qu)

end
@#$#@#$#@
GRAPHICS-WINDOW
553
10
772
230
-1
-1
21.1
1
20
1
1
1
0
1
1
1
0
9
0
9
1
1
1
ticks
30.0

BUTTON
7
48
77
81
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
5
10
68
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
17
341
127
374
formation
formation
0
1
-1000

SWITCH
17
381
120
414
mae
mae
0
1
-1000

PLOT
1023
10
1223
160
Concentration de nitrate
ticks
C
0.0
55.0
0.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -14070903 true "" "plot C"

MONITOR
913
10
970
55
NIL
C
3
1
11

SLIDER
11
189
103
222
%_type1
%_type1
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
136
344
261
377
niv_forma
niv_forma
0
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
139
381
264
414
niv_mae
niv_mae
0
900
300.0
25
1
NIL
HORIZONTAL

TEXTBOX
27
305
261
324
GOVERNANCE
16
125.0
1

TEXTBOX
487
240
844
278
FARMERS CARACTERISTICS\n(type 1 - ecofriendly; type 2 - economicus)
16
125.0
1

TEXTBOX
11
92
161
110
INITIALISATION
14
125.0
1

TEXTBOX
585
450
750
477
Standard deviation of normal law for threshold
12
0.0
1

SLIDER
11
118
103
151
nbAgri
nbAgri
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
587
288
679
321
gAtt
gAtt
0
100
66.0
5
1
NIL
HORIZONTAL

SLIDER
689
289
781
322
gSN
gSN
0
1
34.0
0.05
1
NIL
HORIZONTAL

TEXTBOX
490
329
757
374
Attitude, perceived behavioural control and subjective norm weights in intention to change farming practice\n
12
0.0
1

TEXTBOX
528
501
785
535
Attitude towards environnement
14
125.0
1

PLOT
1242
10
1442
160
%nbAgriBio total
ticks
%
0.0
20.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count agri with [K = 0]) / (count agri ) * 100"

PLOT
1459
10
1659
160
%nbAgriBio par type
ticks
%
0.0
20.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot (count agri with [K = 0 and typ = 2]) / (count agri with [typ = 2]) * 100"
"pen-1" 1.0 0 -13840069 true "" "plot( count agri with [K = 0 and typ = 1]) / (count agri with [typ = 1]) * 100"

TEXTBOX
225
101
394
178
Fond\n- vert : high-input\n- bleu : low-input\n- rouge : high-input and was low-input
12
0.0
1

MONITOR
847
152
964
197
MAE Total costs
costs
17
1
11

SLIDER
168
304
260
337
dK
dK
0
10
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
279
309
429
339
Minimal duration of involvement in program
12
0.0
1

SWITCH
13
267
116
300
retour
retour
1
1
-1000

TEXTBOX
125
267
275
297
Possibility to return to conventional farming
12
0.0
1

SLIDER
481
409
573
442
Normal
Normal
0
1
0.5
0.05
1
NIL
HORIZONTAL

TEXTBOX
587
409
707
439
Average of normal law for threshold
12
0.0
1

BUTTON
179
11
242
44
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
89
49
152
82
NIL
init\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
482
449
574
482
ET
ET
0
0.5
0.125
0.05
1
NIL
HORIZONTAL

SLIDER
118
191
210
224
e1
e1
0
1
1.0
0.1
1
NIL
HORIZONTAL

PLOT
1030
167
1199
298
Agri typ 1 from D to Z
ticks
a_z, s_z, p_z
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot (totAtt_1ZD  )"
"pen-1" 1.0 0 -2674135 true "" "plot (totSN_1ZD  )"
"pen-2" 1.0 0 -1184463 true "" "plot (totPC_1ZD  )"

MONITOR
1207
162
1289
207
NIL
totAtt_1ZD
3
1
11

MONITOR
1208
208
1291
253
NIL
totSN_1ZD
3
1
11

MONITOR
1208
254
1290
299
NIL
totPC_1ZD
3
1
11

PLOT
1426
169
1622
295
Agri typ 1 from Z to D
tickes
a_d,s_d,z_d
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot (totAtt_1DZ  )"
"pen-1" 1.0 0 -2674135 true "" "plot (totSN_1DZ)"
"pen-2" 1.0 0 -1184463 true "" "plot (totPC_1DZ)"

MONITOR
1627
161
1709
206
NIL
totAtt_1DZ
3
1
11

MONITOR
1627
208
1710
253
NIL
totSN_1DZ
3
1
11

MONITOR
1626
255
1708
300
NIL
totPC_1DZ
3
1
11

MONITOR
1348
307
1414
352
NIL
cagriz_1
17
1
11

MONITOR
953
325
1028
370
NIL
cagrid_1
17
1
11

PLOT
1034
447
1201
582
Agri typ 2 from D to Z
ticks
NIL
0.0
2.0
-0.25
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot (totAtt_2ZD  )"
"pen-1" 1.0 0 -2674135 true "" "plot (totSN_2ZD  )"
"pen-2" 1.0 0 -1184463 true "" "plot (totPC_2ZD  )"

MONITOR
1210
444
1292
489
NIL
totAtt_2ZD
3
1
11

MONITOR
1209
492
1292
537
NIL
totSN_2ZD
3
1
11

MONITOR
1210
538
1292
583
NIL
totPC_2ZD
3
1
11

PLOT
1432
443
1624
580
Agri typ 2 from Z to D
ticks
NIL
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot totAtt_2DZ"
"pen-1" 1.0 0 -2674135 true "" "plot totSN_2DZ"
"pen-2" 1.0 0 -1184463 true "" "plot totPC_2DZ"

MONITOR
1633
441
1715
486
NIL
totAtt_2DZ
3
1
11

MONITOR
1632
488
1715
533
NIL
totSN_2DZ
3
1
11

MONITOR
1632
535
1714
580
NIL
totPC_2DZ
3
1
11

MONITOR
958
591
1027
636
NIL
cagrid_2
17
1
11

MONITOR
1355
565
1421
610
NIL
cagriz_2
17
1
11

SWITCH
411
116
531
149
showLinks?
showLinks?
0
1
-1000

BUTTON
77
12
171
45
go20fois
repeat 20 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
160
47
260
82
NIL
paramInit
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
592
142
625
Cinit
Cinit
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
153
592
268
627
initiale concentration\n
12
0.0
1

SLIDER
483
288
575
321
gPCB
gPCB
0
1
0.33
0.01
1
NIL
HORIZONTAL

MONITOR
849
46
906
91
NIL
farmZ
17
1
11

MONITOR
850
98
924
143
NIL
farmStop
17
1
11

MONITOR
1627
303
1710
348
NIL
totAtt_1ZZ
17
1
11

PLOT
1426
303
1612
433
Agri typ 1 from Z to Z
NIL
NIL
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot (totAtt_1ZZ  )"
"pen-1" 1.0 0 -2674135 true "" "plot (totSN_1ZZ  )"
"pen-2" 1.0 0 -1184463 true "" "plot (totPC_1ZZ  )"

MONITOR
1625
348
1710
393
NIL
totSN_1ZZ
3
1
11

MONITOR
1625
394
1708
439
NIL
totPC_1ZZ
17
1
11

MONITOR
1210
303
1291
348
NIL
totAtt_1DD
17
1
11

MONITOR
1211
349
1293
394
NIL
totSN_1DD
17
1
11

MONITOR
1211
396
1292
441
NIL
totPC_1DD
3
1
11

PLOT
1035
311
1201
439
Agri typ 1 from D to D
NIL
NIL
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot (totAtt_1DD  )"
"pen-1" 1.0 0 -2674135 true "" "plot (totSN_1DD  )"
"pen-2" 1.0 0 -1184463 true "" "plot (totPC_1DD  )"

MONITOR
1633
582
1716
627
NIL
totAtt_2ZZ
17
1
11

MONITOR
1633
627
1718
672
NIL
totSN_2ZZ
3
1
11

MONITOR
1634
675
1717
720
NIL
totPC_2ZZ
17
1
11

PLOT
1433
586
1630
715
Agri typ 2 from Z to Z
NIL
NIL
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot totAtt_2ZZ"
"pen-1" 1.0 0 -2674135 true "" "plot totSN_2ZZ"
"pen-2" 1.0 0 -1184463 true "" "plot totPC_2ZZ"

PLOT
1034
586
1208
710
Agri typ 2 from D to D
NIL
NIL
0.0
20.0
-0.25
2.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot totAtt_2DD"
"pen-1" 1.0 0 -2674135 true "" "plot totSN_2DD"
"pen-2" 1.0 0 -1184463 true "" "plot totPC_2DD"

MONITOR
1211
584
1292
629
NIL
totAtt_2DD
3
1
11

MONITOR
1211
630
1293
675
NIL
totSN_2DD
17
1
11

MONITOR
1211
677
1292
722
NIL
totPC_2DD
3
1
11

TEXTBOX
15
567
254
585
ECOLOGICAL RESOURCE
16
125.0
1

TEXTBOX
826
15
976
34
OUTPUTS
16
125.0
1

SLIDER
224
191
316
224
e2
e2
0
1
0.0
0.1
1
NIL
HORIZONTAL

TEXTBOX
29
430
179
448
Scenario
12
125.0
1

MONITOR
272
57
403
102
NIL
clustering-coefficient
17
1
11

MONITOR
409
60
543
105
NIL
average-path-length
17
1
11

MONITOR
445
10
543
55
NIL
S-smallworld
17
1
11

SLIDER
397
155
535
188
rewiring-probability
rewiring-probability
0
1
0.5
0.1
1
NIL
HORIZONTAL

CHOOSER
790
284
882
329
pop
pop
"pop0" "pop1" "pop2" "pop3" "pop4"
1

CHOOSER
27
447
119
492
sc
sc
0 1 2 3 4 5 6 7
0

MONITOR
856
219
915
264
I_type1
I_type1
17
1
11

MONITOR
922
220
981
265
I_type2
I_type2
17
1
11

SLIDER
119
118
211
151
nbLow
nbLow
0
80
0.0
1
1
NIL
HORIZONTAL

SLIDER
145
431
262
464
niv_forma2
niv_forma2
0
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
145
465
256
498
niv_mae2
niv_mae2
0
600
300.0
25
1
NIL
HORIZONTAL

TEXTBOX
754
334
923
401
pop1 : equal weigts\npop2 : attitude-influenced\npop3 : PCB-influence\npop4 : NS-influenced
12
0.0
1

BUTTON
249
10
336
43
1000go
repeat 500 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
279
370
379
516
sc0: niv_form2 and niv_mae2\nsc1: 400 / 0\nsc2: 400 / 0.2\nsc3: 400 / 0.4\nsc4: 400 / 0.5 \nsc5: 345.5 / 0.2\nsc6: 348 / 0.4\nsc7: 350 / 0.5
12
0.0
1

SLIDER
12
633
104
666
Q
Q
0
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
120
633
212
666
ED
ED
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
223
633
315
666
G
G
0
100
50.0
10
1
NIL
HORIZONTAL

CHOOSER
23
509
115
554
Typ_eP_on
Typ_eP_on
1 2 3 4 5
2

SLIDER
227
556
319
589
%info
%info
0
100
50.0
5
1
NIL
HORIZONTAL

SLIDER
124
517
249
550
%info_typ
%info_typ
0
100
100.0
5
1
NIL
HORIZONTAL

SLIDER
348
11
440
44
nbGo
nbGo
0
100
20.0
20
1
NIL
HORIZONTAL

SLIDER
530
530
622
563
qep
qep
0
25
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
18
162
88
180
Type
14
125.0
1

TEXTBOX
333
512
447
662
If Typ_eP_on = 1 ; % type 1 informed\nIf Typ_eP_on = 2 ; % type 2 informed\nIf Typ_eP_on = 3 ; all informed\nIf Typ_eP_on = 4 ; %info informed \nIf Typ_eP_on = 5 ; no informed
12
0.0
1

SLIDER
630
530
722
563
alphep
alphep
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
527
581
619
614
NCnoI
NCnoI
0
100
35.0
1
1
NIL
HORIZONTAL

SLIDER
627
581
719
614
ETCnoI
ETCnoI
0
25
5.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="expe_1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count agri</metric>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="formation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ET">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compare">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dK">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retour">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_forma">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gAtt">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_mae">
      <value value="260"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gSN">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbAgri">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_gpEcoFd">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mae">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e1">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Normal">
      <value value="0.6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="varNbAgri" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <steppedValueSet variable="nbAgri" first="8" step="4" last="100"/>
  </experiment>
  <experiment name="varEcoFriendly" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="%_type1" first="0" step="10" last="100"/>
  </experiment>
  <experiment name="varMAE" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="niv_mae" first="0" step="10" last="600"/>
  </experiment>
  <experiment name="varForma" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="niv_forma" first="0" step="0.05" last="1"/>
  </experiment>
  <experiment name="varSeuil" repetitions="200" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <steppedValueSet variable="Normal" first="0" step="0.05" last="1"/>
  </experiment>
  <experiment name="varET" repetitions="200" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <steppedValueSet variable="ET" first="0" step="0.05" last="1"/>
  </experiment>
  <experiment name="varMAEForma" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri</metric>
    <steppedValueSet variable="niv_mae" first="0" step="25" last="600"/>
    <steppedValueSet variable="niv_forma" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="varAtt" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri</metric>
    <steppedValueSet variable="gAtt" first="0" step="0.05" last="1"/>
    <steppedValueSet variable="gPCB" first="0" step="0.05" last="1"/>
  </experiment>
  <experiment name="vare1" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri with [Ap = 1]</metric>
    <metric>count agri with [Ap = 2]</metric>
    <metric>count agri with [Ap = 1 and K = 0]</metric>
    <metric>count agri with [Ap = 2 and K = 0]</metric>
    <metric>count agri</metric>
    <metric>count agri with [Ap = 1 and typ = 1]</metric>
    <metric>count agri with [Ap = 2 and typ = 1]</metric>
    <steppedValueSet variable="e1" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="varMAEForma+Att" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri with [Ap = 1]</metric>
    <metric>count agri with [Ap = 2]</metric>
    <metric>count agri with [Ap = 1 and K = 0]</metric>
    <metric>count agri with [Ap = 2 and K = 0]</metric>
    <metric>count agri</metric>
    <steppedValueSet variable="gAtt" first="0" step="0.25" last="1"/>
    <steppedValueSet variable="gSN" first="0" step="0.25" last="1"/>
    <steppedValueSet variable="niv_mae" first="0" step="50" last="500"/>
    <steppedValueSet variable="niv_forma" first="0" step="0.05" last="0.5"/>
  </experiment>
  <experiment name="vareCinit" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri with [Ap = 1]</metric>
    <metric>count agri with [Ap = 2]</metric>
    <metric>count agri with [Ap = 1 and K = 0]</metric>
    <metric>count agri with [Ap = 2 and K = 0]</metric>
    <metric>count agri</metric>
    <metric>count agri with [Ap = 1 and typ = 1]</metric>
    <metric>count agri with [Ap = 2 and typ = 1]</metric>
    <steppedValueSet variable="Cinit" first="41" step="2" last="71"/>
  </experiment>
  <experiment name="varMAEForma+Cinit" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri with [Ap = 1]</metric>
    <metric>count agri with [Ap = 2]</metric>
    <metric>count agri with [Ap = 1 and K = 0]</metric>
    <metric>count agri with [Ap = 2 and K = 0]</metric>
    <metric>count agri</metric>
    <steppedValueSet variable="Cinit" first="41" step="2" last="61"/>
    <steppedValueSet variable="niv_mae" first="0" step="50" last="500"/>
    <steppedValueSet variable="niv_forma" first="0" step="0.05" last="0.5"/>
  </experiment>
  <experiment name="vardNB" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="dNB" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="varNet" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="nbNetwork">
      <value value="2"/>
      <value value="8"/>
      <value value="16"/>
      <value value="32"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="expe_learn_forma" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_z_1</metric>
    <metric>totSN_z_2</metric>
    <steppedValueSet variable="niv_forma" first="0" step="0.05" last="1"/>
  </experiment>
  <experiment name="varTNw" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="wTNw" first="0" step="0.05" last="1"/>
  </experiment>
  <experiment name="varNewMAE" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="newNiv_mae" first="0" step="25" last="400"/>
  </experiment>
  <experiment name="fisher" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="niv_mae">
      <value value="100"/>
      <value value="300"/>
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_forma">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gAtt">
      <value value="0.1"/>
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.7"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gPCB">
      <value value="0.1"/>
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.7"/>
      <value value="0.9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="network" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>stop</go>
    <metric>clustering-coefficient</metric>
    <metric>average-path-length</metric>
  </experiment>
  <experiment name="rewi-p" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>stop</go>
    <metric>clustering-coefficient</metric>
    <metric>average-path-length</metric>
    <metric>S-smallworld</metric>
  </experiment>
  <experiment name="expe_20-07-16" repetitions="1000" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>count agri</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="pop">
      <value value="&quot;pop1&quot;"/>
      <value value="&quot;pop2&quot;"/>
      <value value="&quot;pop3&quot;"/>
      <value value="&quot;pop4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sc">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="expe_20-07-17" repetitions="500" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="formation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Csens">
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dK">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retour">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gAtt">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gSN">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eP_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nwG_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_mae2">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gPCB">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ET">
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="showLinks?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop">
      <value value="&quot;pop2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_forma">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_mae">
      <value value="411"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_type1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cinit">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sc">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wTNw">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbAgri">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_forma2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e1">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probaLow">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Normal">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="expe_20-08-11" repetitions="3000" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="probaLow" first="0" step="1" last="80"/>
  </experiment>
  <experiment name="expe_20-09-03" repetitions="1000" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="probaLow" first="0" step="1" last="80"/>
  </experiment>
  <experiment name="part3-1-1" repetitions="1000" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="gAtt" first="0" step="0.01" last="0.66"/>
  </experiment>
  <experiment name="varForma_part3-2-2" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="niv_forma" first="0" step="0.01" last="1"/>
  </experiment>
  <experiment name="expe2809" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
  </experiment>
  <experiment name="expe2311" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
  </experiment>
  <experiment name="expe23110112-fin" repetitions="10000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="formation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Csens">
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dK">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retour">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gAtt">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gSN">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eP_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nwG_on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_mae2">
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gPCB">
      <value value="0.33333"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ET">
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e2">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="showLinks?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop">
      <value value="&quot;pop2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_forma">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_mae">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_type1">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Cinit">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sc">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wTNw">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nbAgri">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="niv_forma2">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="e1">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probaLow">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Normal">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="nbLow" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="probaLow" first="0" step="5" last="100"/>
    <steppedValueSet variable="gSN" first="0" step="0.02" last="0.66"/>
  </experiment>
  <experiment name="nbEco" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="%_type1" first="0" step="5" last="100"/>
    <steppedValueSet variable="gAtt" first="0" step="0.05" last="0.65"/>
  </experiment>
  <experiment name="weigts" repetitions="20" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="gSN" first="0" step="0.02" last="1"/>
    <steppedValueSet variable="gAtt" first="0" step="0.02" last="1"/>
  </experiment>
  <experiment name="attE" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="attE" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="Typ_eP_on" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Typ_eP_on" first="1" step="1" last="5"/>
  </experiment>
  <experiment name="%info" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="Typ_eP_on">
      <value value="4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%info" first="0" step="10" last="100"/>
  </experiment>
  <experiment name="%info_typ1" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="Typ_eP_on">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%info_typ" first="0" step="10" last="100"/>
  </experiment>
  <experiment name="expe" repetitions="200" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="nbGo">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cinit" repetitions="5000" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cinit" first="0" step="5" last="100"/>
  </experiment>
  <experiment name="Cmax" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cmax" first="30" step="10" last="100"/>
  </experiment>
  <experiment name="G" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="G" first="0" step="10" last="100"/>
  </experiment>
  <experiment name="CmaxCinit" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cmax" first="20" step="20" last="100"/>
    <steppedValueSet variable="Cinit" first="0" step="20" last="100"/>
  </experiment>
  <experiment name="CmaxCsens" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cmax" first="0" step="5" last="100"/>
    <steppedValueSet variable="Csens" first="0" step="5" last="100"/>
  </experiment>
  <experiment name="CinitCsens" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cinit" first="0" step="20" last="100"/>
    <steppedValueSet variable="Csens" first="0" step="20" last="100"/>
  </experiment>
  <experiment name="CinitG" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cinit" first="0" step="20" last="100"/>
    <steppedValueSet variable="G" first="0" step="20" last="100"/>
  </experiment>
  <experiment name="CmaxG" repetitions="5" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cmax" first="0" step="5" last="100"/>
    <steppedValueSet variable="G" first="0" step="5" last="100"/>
  </experiment>
  <experiment name="GCsens" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="G" first="0" step="20" last="100"/>
    <steppedValueSet variable="Csens" first="0" step="20" last="100"/>
  </experiment>
  <experiment name="ED" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="ED" first="0" step="5" last="100"/>
  </experiment>
  <experiment name="Csens" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Csens" first="0" step="5" last="50"/>
  </experiment>
  <experiment name="CMax%info" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="Cmax" first="0" step="10" last="100"/>
    <steppedValueSet variable="%info" first="0" step="10" last="100"/>
  </experiment>
  <experiment name="e1e2" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="e1" first="0" step="0.1" last="1"/>
    <steppedValueSet variable="e2" first="0" step="0.1" last="1"/>
  </experiment>
  <experiment name="typOn" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <enumeratedValueSet variable="typOn">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CmaxET" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="CmaxET" first="0" step="10" last="50"/>
  </experiment>
  <experiment name="CmaxN" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="CmaxN" first="0" step="10" last="100"/>
  </experiment>
  <experiment name="CmaxNCmaxET" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="CmaxN" first="25" step="5" last="100"/>
    <steppedValueSet variable="CmaxET" first="0" step="5" last="25"/>
  </experiment>
  <experiment name="alphep" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="alphep" first="0" step="5" last="100"/>
  </experiment>
  <experiment name="qep" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="qep" first="0" step="5" last="25"/>
  </experiment>
  <experiment name="alphepqep" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="alphep" first="0" step="5" last="100"/>
    <steppedValueSet variable="qep" first="0" step="5" last="25"/>
  </experiment>
  <experiment name="probaLow" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>C</metric>
    <metric>count agri with [K = 0 and typ = 2]</metric>
    <metric>count agri with [K = 0 and typ = 1]</metric>
    <metric>count agri with [K = 0 ]</metric>
    <metric>I_type1</metric>
    <metric>I_type2</metric>
    <metric>farmZ</metric>
    <metric>totSN_2DZ</metric>
    <metric>totSN_2ZD</metric>
    <metric>totSN_1DZ</metric>
    <metric>totSN_1ZD</metric>
    <metric>totSN_2DD</metric>
    <metric>totSN_2ZZ</metric>
    <metric>totSN_1DD</metric>
    <metric>totSN_1ZZ</metric>
    <metric>totPC_2DZ</metric>
    <metric>totPC_2ZD</metric>
    <metric>totPC_1DZ</metric>
    <metric>totPC_1ZD</metric>
    <metric>totPC_2DD</metric>
    <metric>totPC_2ZZ</metric>
    <metric>totPC_1DD</metric>
    <metric>totPC_1ZZ</metric>
    <metric>totAtt_2DZ</metric>
    <metric>totAtt_2ZD</metric>
    <metric>totAtt_1DZ</metric>
    <metric>totAtt_1ZD</metric>
    <metric>totAtt_2DD</metric>
    <metric>totAtt_2ZZ</metric>
    <metric>totAtt_1DD</metric>
    <metric>totAtt_1ZZ</metric>
    <steppedValueSet variable="probaLow" first="0" step="1" last="100"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
