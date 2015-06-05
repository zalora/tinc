
module PackageGraph (fromDot) where

import           Control.Monad
import           Data.Functor
import           Data.Graph.Wrapper as G
import           Data.Map as Map (empty, Map, toList, alter)
import           Data.Maybe
import           Language.Dot.Parser as Dot
import           Language.Dot.Syntax as Dot
import           Text.Parsec.Error

import           Package

type PackageGraph = G.Graph Package ()

fromDot :: String -> Either String PackageGraph
fromDot dot = case parseDot "<input>" dot of
  Right (Dot.Graph _ _ _ statements) ->
    fmap fromMap $
    foldM collectStatements Map.empty statements
  Left parseError -> Left $ unlines $ map messageString $ errorMessages parseError

collectStatements :: Map Package [Package] -> Statement -> Either String (Map Package [Package])
collectStatements acc s = case s of
  NodeStatement a _ ->
    return $ alter (Just . fromMaybe []) (toString a) acc
  EdgeStatement [ENodeId _ a, ENodeId _ b] _ ->
    return $
    alter (Just . fromMaybe []) (toString b) $
    alter (fmap (toString b :) . Just . fromMaybe []) (toString a) acc
  x -> Left ("unsupported dot statements: " ++ show x)

fromMap :: Ord a => Map a [a] -> G.Graph a ()
fromMap m = () <$ (G.fromListSimple $ Map.toList m)

toString :: NodeId -> Package
toString (NodeId i _) = parsePackage $ case i of
  NameId s -> s
  StringId s -> s
  IntegerId i -> show i
  FloatId f -> show f
  x@XmlId{} -> show x
