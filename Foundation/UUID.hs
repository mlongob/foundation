{-# LANGUAGE UnboxedTuples #-}
module Foundation.UUID
    ( UUID(..)
    , nil
    , fromBinary
    ) where

import           Foundation.Internal.Base
import           Foundation.Class.Storable
import           Foundation.Hashing.Hashable
import           Foundation.Bits
import           Foundation.Primitive
import           Foundation.Primitive.Base16
import           Foundation.Primitive.IntegralConv
import qualified Foundation.Array.Unboxed as UA

data UUID = UUID {-# UNPACK #-} !Word64 {-# UNPACK #-} !Word64
    deriving (Eq,Ord,Typeable)
instance Show UUID where
    show = toLString
instance Hashable UUID where
    hashMix (UUID a b) = hashMix a . hashMix b
instance Storable UUID where
    peek p = UUID <$> (fromBE <$> peekOff ptr 0)
                  <*> (fromBE <$> peekOff ptr 1)
      where ptr = castPtr p :: Ptr (BE Word64)
    poke p (UUID a b) = do
        pokeOff ptr 0 (toBE a)
        pokeOff ptr 1 (toBE b)
      where ptr = castPtr p :: Ptr (BE Word64)
instance StorableFixed UUID where
    size      _ = 16
    alignment _ = 8

withComponent :: UUID -> (Word32 -> Word16 -> Word16 -> Word16 -> Word64 -> a) -> a
withComponent (UUID a b) f = f x1 x2 x3 x4 x5
  where
    !x1 = integralDownsize (a .>>. 32)
    !x2 = integralDownsize ((a .>>. 16) .&. 0xffff)
    !x3 = integralDownsize (a .&. 0xffff)
    !x4 = integralDownsize (b .>>. 48)
    !x5 = (b .&. 0x0000ffffffffffff)
{-# INLINE withComponent #-}

toLString :: UUID -> [Char]
toLString uuid = withComponent uuid $ \x1 x2 x3 x4 x5 ->
    hexWord_4 x1 $ addDash $ hexWord_2 x2 $ addDash $ hexWord_2 x3 $ addDash $ hexWord_2 x4 $ addDash $ hexWord64_6 x5 []
  where
    addDash = (:) '-'
    hexWord_2 w l = case hexWord16 w of
                         (c1,c2,c3,c4) -> c1:c2:c3:c4:l
    hexWord_4 w l = case hexWord32 w of
                    (c1,c2,c3,c4,c5,c6,c7,c8) -> c1:c2:c3:c4:c5:c6:c7:c8:l
    hexWord64_6 w l = case word64ToWord32s w of
                        (# wHigh, wLow #) -> hexWord_2 (integralDownsize wHigh) $ hexWord_4 wLow l

nil :: UUID
nil = UUID 0 0

fromBinary :: UA.UArray Word8 -> Maybe UUID
fromBinary ba
    | UA.length ba /= 16 = Nothing
    | otherwise          = Just $ UUID w0 w1
  where
    w0 = (b15 .<<. 56) .|. (b14 .<<. 48) .|. (b13 .<<. 40) .|. (b12 .<<. 32) .|.
         (b11 .<<. 24) .|. (b10 .<<. 16) .|. (b9 .<<. 8)   .|. b8
    w1 = (b7 .<<. 56) .|. (b6 .<<. 48) .|. (b5 .<<. 40) .|. (b4 .<<. 32) .|.
         (b3 .<<. 24) .|. (b2 .<<. 16) .|. (b1 .<<. 8)  .|. b0

    b0  = integralUpsize (UA.unsafeIndex ba 0)
    b1  = integralUpsize (UA.unsafeIndex ba 1)
    b2  = integralUpsize (UA.unsafeIndex ba 2)
    b3  = integralUpsize (UA.unsafeIndex ba 3)
    b4  = integralUpsize (UA.unsafeIndex ba 4)
    b5  = integralUpsize (UA.unsafeIndex ba 5)
    b6  = integralUpsize (UA.unsafeIndex ba 6)
    b7  = integralUpsize (UA.unsafeIndex ba 7)
    b8  = integralUpsize (UA.unsafeIndex ba 8)
    b9  = integralUpsize (UA.unsafeIndex ba 9)
    b10 = integralUpsize (UA.unsafeIndex ba 10)
    b11 = integralUpsize (UA.unsafeIndex ba 11)
    b12 = integralUpsize (UA.unsafeIndex ba 12)
    b13 = integralUpsize (UA.unsafeIndex ba 13)
    b14 = integralUpsize (UA.unsafeIndex ba 14)
    b15 = integralUpsize (UA.unsafeIndex ba 15)
