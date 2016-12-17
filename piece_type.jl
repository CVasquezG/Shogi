
##Pieces
type Piece
    color::AbstractString
    name::AbstractString
end

#Is a piece an empty square?
function isNullPiece(piece::Piece)
  return piece.name == "-"
end

#Are two pieces functionally identical? (Same colour and name)
function ==(a::Piece, b::Piece)
  return a.color == b.color && a.name == b.name
end

##############DATABASE NAMES########################

#Standard
const DBishop = "bishop"
const DGoldGeneral = "gold general"
const DKing =  "king"
const DLance = "lance"
const DKnight = "knight"
const DPawn =  "pawn"
const DRook = "rook"
const DSilverGeneral = "silver general"
#Chu shogi
const DReverseChariot = "reverse chariot"
const DCopperGeneral = "copper general"
const DDragonKing = "dragon king"
const DDrunkenElephant = "drunken elephant"
const DFerociousLeopard = "ferocious leopard"
const DDragonHorse = "dragon horse"
const DLion = "lion"
const DSideMover = "side mover"
const DKirin = "kirin"
const DGoBetween = "go between"
const DBlindTiger = "blind tiger"
const DQueen = "queen"
const DVerticalMover = "vertical mover"
const DPhoenix = "phoenix"
#Tenjiku Shogi
const DBishopGeneral = "bishop general"
const DChariotSoldier = "chariot soldier"
const DDog = "dog"
const DFireDemon = "fire demon"
const DFreeEagle = "free eagle"
const DGreatGeneral = "great general"
const DHornedFalcon = "horned falcon"
const DIronGeneral = "iron general"
const DLionHawk = "lion hawk"
const DRookGeneral = "rook general"
const DSideSoldier = "side soldier"
const DSoaringEagle = "soaring eagle"
const DVerticalSoldier = "vertical soldier"
const DViceGeneral = "vice general"
const DWaterBuffalo = "water buffalo"

#Standard                                           S/C/T
const DPBishop = "promoted bishop"                  #Dragon Horse
const DPLance = "promoted lance"                    #Gold General/White Horse
const DPKnight = "promoted knight"                  #Gold General/ /SIde Soldier
const DPPawn =  "promoted pawn"                     #Gold General
const DPRook = "promoted rook"                      #Dragon King
const DPSilverGeneral = "promoted silver general"    #Gold General/Vertical Mover
#Chu Shogi
const DPReverseChariot = "promoted reverse chariot"  #Whale
const DPCopperGeneral = "promoted copper general"    #Side Mover
const DPDragonKing = "promoted dragon king"          #Soaring Eagle
const DPDrunkenElephant = "promoted drunken elephant"#Prince
const DPFerociousLeopard = "promoted ferocious lepard"     #Bishop
const DPDragonHorse = "promoted dragon horse"          #Horned Falcon
const DPSideMover = "promoted side mover"            #Free Boar
const DPKirin = "promoted kirin"                #Lion
const DPGoBetween = "promoted go between"            #Drunken Elephant
const DPGoldGeneral = "promoted gold general"        #Rook
const DPBlindTiger = "promoted blind tiger"           #Flying Stag
const DPVerticalMover = "promoted vertical mover"        #Flying Ox
const DPPhoenix = "promoted phoenix"              #Queen
#Tenjiku Shogi
const DPBishopGeneral = "promoted bishop general"  #Vice General
const DPChariotSoldier = "promoted chariot soldier"   #Heavenly Tetrarch
const DPDog = "promoted dog"                       #Multi General
const DPHornedFalcon = "promoted horned falcon"    #Bishop General
const DPIronGeneral = "promoted iron general"      #Vertical Soldier
const DPLion = "promoted lion"                     #Lion Hawk
const DPQueen = "promoted queen"                   #Free Eagle
const DPRookGeneral = "promoted rook general"      #Great General
const DPSideSoldier = "promoted side soldier"      #Water Buffalo
const DPSoaringEagle = "promoted soaring eagle"    #Rook General
const DPVerticalSoldier = "promoted vertical soldier"    #Chariot Soldier
const DPWaterBuffalo = "promoted water buffalo"     #Fire Demon

############NAMES###################
#Standard
const Bishop = "b"
const GoldGeneral = "g"
const King =  "k"
const Lance = "l"
const Knight = "n"
const Pawn =  "p"
const Rook = "r"
const SilverGeneral = "s"
#Chu shogi
const ReverseChariot = "rc"
const CopperGeneral = "c"
const DragonKing = "dk"
const DrunkenElephant = "de"
const FerociousLeopard = "fl"
const DragonHorse = "dh"
const Lion = "ln"
const SideMover = "sm"
const Kirin = "kr"
const GoBetween = "o"
const BlindTiger = "bt"
const Queen = "q"
const VerticalMover = "vm"
const Phoenix = "ph"
#Tenjiku Shogi
const BishopGeneral = "bg"
const ChariotSoldier = "cs"
const Dog = "d"
const FireDemon = "fd"
const FreeEagle = "fe"
const GreatGeneral = "gg"
const HornedFalcon = "hf"
const IronGeneral = "i"
const LionHawk = "lh"
const RookGeneral = "rg"
const SideSoldier = "ss"
const SoaringEagle = "se"
const VerticalSoldier = "vs"
const ViceGeneral = "vg"
const WaterBuffalo = "wb"

#Standard                                           S/C/T
const PBishop = "B"                  #Dragon Horse
const PLance = "L"                    #Gold General/White Horse
const PKnight = "N"                  #Gold General/ /SIde Soldier
const PPawn =  "P"                     #Gold General
const PRook = "R"                      #Dragon King
const PSilverGeneral = "S"    #Gold General/Vertical Mover
#Chu Shogi
const PReverseChariot = "RC"  #Whale
const PCopperGeneral = "C"    #Side Mover
const PDragonKing = "DK"          #Soaring Eagle
const PDrunkenElephant = "DE"#Prince
const PFerociousLeopard = "FL"     #Bishop
const PDragonHorse = "DH"          #Horned Falcon
const PSideMover = "SM"            #Free Boar
const PKirin = "KR"                #Lion
const PGoBetween = "O"            #Drunken Elephant
const PGoldGeneral = "G"        #Rook
const PBlindTiger = "BT"           #Flying Stag
const PVerticalMover = "VM"        #Flying Ox
const PPhoenix = "PH"              #Queen
#Tenjiku Shogi
const PBishopGeneral = "BG"  #Vice General
const PChariotSoldier = "CS"   #Heavenly Tetrarch
const PDog = "D"                       #Multi General
const PHornedFalcon = "HF"    #Bishop General
const PIronGeneral = "I"      #Vertical Soldier
const PLion = "LN"                     #Lion Hawk
const PQueen = "Q"                   #Free Eagle
const PRookGeneral = "RG"      #Great General
const PSideSoldier = "SS"      #Water Buffalo
const PSoaringEagle = "SE"    #Rook General
const PVerticalSoldier = "VS"    #Chariot Soldier
const PWaterBuffalo = "WB"     #Fire Demon


######ARRAYS FOR PROMOTING################
#=Each array is the same size, and each element has a corresponding element in another array
Example: arrDatabaseNames[6] = DPawn = "pawn"
         arrDatabaseProNames[6] = DPPawn = "promoted_pawn"
         arrAbbNames[6] = Pawn = "p"
         arrAbbProNames[6] = PPawn = "P"
=#



arrDatabaseNames = [#Standard
                    DBishop, DGoldGeneral, DKing, DLance, DKnight, DPawn, DRook, DSilverGeneral,
                    #Chu
                    DReverseChariot, DCopperGeneral, DDragonKing, DDrunkenElephant, DFerociousLeopard, DDragonHorse, DLion, DSideMover, DKirin, DGoBetween,
                    DBlindTiger, DQueen, DVerticalMover, DPhoenix,
                    #ten
                    DBishopGeneral, DChariotSoldier, DDog, DFireDemon, DFreeEagle, DGreatGeneral, DHornedFalcon, DIronGeneral, DLionHawk, DRookGeneral, DSideSoldier,
                    DSoaringEagle, DVerticalSoldier, DViceGeneral, DWaterBuffalo,
                    ]
arrDatabaseProNames = [#standard
                    DPBishop, DPGoldGeneral, DKing, DPLance, DPKnight, DPPawn, DPRook, DPSilverGeneral,
                    #chu
                    DPReverseChariot, DPCopperGeneral, DPDragonKing, DPDrunkenElephant, DPFerociousLeopard, DPDragonHorse, DPLion, DPSideMover, DPKirin, DPGoBetween,
                    DPBlindTiger, DPQueen, DPVerticalMover, DPPhoenix,
                    #ten
                    DPBishopGeneral, DPChariotSoldier, DPDog, DFireDemon, DFreeEagle, DGreatGeneral, DPHornedFalcon, DPIronGeneral, DLionHawk, DPRookGeneral, DPSideSoldier,
                    DPSoaringEagle, DPVerticalSoldier, DViceGeneral, DPWaterBuffalo
                    ]

arrAbbNames = [#Standard
                Bishop, GoldGeneral, King, Lance, Knight, Pawn, Rook, SilverGeneral,
                #Chu
                ReverseChariot, CopperGeneral, DragonKing, DrunkenElephant, FerociousLeopard, DragonHorse, Lion, SideMover, Kirin, GoBetween,
                BlindTiger, Queen, VerticalMover, Phoenix,
                #ten
                BishopGeneral, ChariotSoldier, Dog, FireDemon, FreeEagle, GreatGeneral, HornedFalcon, IronGeneral, LionHawk, RookGeneral, SideSoldier,
                SoaringEagle, VerticalSoldier, ViceGeneral, WaterBuffalo,
                ]
arrAbbProNames = [#standard
                PBishop, PGoldGeneral, King, PLance, PKnight, PPawn, PRook, PSilverGeneral,
                #chu
                PReverseChariot, PCopperGeneral, PDragonKing, PDrunkenElephant, PFerociousLeopard, PDragonHorse, PLion, PSideMover, PKirin, PGoBetween,
                PBlindTiger, PQueen, PVerticalMover, PPhoenix,
                #ten
                PBishopGeneral, PChariotSoldier, PDog, FireDemon, FreeEagle, GreatGeneral, PHornedFalcon, PIronGeneral, LionHawk, PRookGeneral, PSideSoldier,
                PSoaringEagle, PVerticalSoldier, ViceGeneral, PWaterBuffalo
                ]

#####PROMOTION FUNCTIONS##########

function promotePiece(piece::Piece)
  for i = 1:length(arrAbbNames)
    if piece.name == arrAbbNames[i]
      piece.name = arrAbbProNames[i]
    end
  end
end
function unpromotePiece(piece::Piece)
  for i = 1:length(arrAbbNames)
    if piece.name == arrAbbProNames[i]
      piece.name = arrAbbNames[i]
    end
  end
end

function isPromoteablePiece(piece::Piece)
  for i = 1:length(arrAbbNames)
    ###if a piece is promoted, it isn't promoteable
    if piece.name == arrAbbProNames[i]
      return false
    end
  end

  #=Unpromoted pieces that are unable to promote:
    Standard: Gold General, King
    Chu: Lion, Queen, King
    Ten: Fire Demon, Free Eagle, Great General, Lion Hawk, Vice General, King=#

  if piece.name == King || piece.name == ViceGeneral || piece.name == LionHawk || piece.name == GreatGeneral || piece.name == FreeEagle || piece.name == FireDemon


    return false
  elseif gameType == "chu" && (piece.name == Queen || piece.name == Lion)
    return false
  elseif (gameType == "standard" || gameType == "minishogi") && piece.name == GoldGeneral
    return false
  else
    return true
  end
end

function getAbbName(name::AbstractString)
  result = nothing
  for i = 1:length(arrAbbNames)
    if name == arrDatabaseNames[i]
      result = arrAbbNames[i]
    elseif name == arrDatabaseProNames[i]
      result = arrAbbProNames[i]
    end
  end

  if result != nothing
    return result
  else
  #  assert(false)
  end
end

function getDatabaseName(name::AbstractString)
  result = nothing
  for i = 1:length(arrAbbNames)
    if name == arrAbbNames[i]
      result = arrDatabaseNames[i]
    elseif name == arrAbbProNames[i]
      result = arrDatabaseProNames[i]
    end
  end

  if result != nothing
    return result
  else
    assert(false)
  end
end
