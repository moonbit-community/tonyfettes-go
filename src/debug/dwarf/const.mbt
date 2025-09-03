/// Constants and enumerations for DWARF debug information format
/// Ported from Go's debug/dwarf package

///|
/// An Attr identifies the attribute type in a DWARF Entry.Field.
pub enum Attr {
  Attr(UInt)
  // DWARF 2
  AttrSibling
  AttrLocation
  AttrName
  AttrOrdering
  AttrByteSize
  AttrBitOffset
  AttrBitSize
  AttrStmtList
  AttrLowpc
  AttrHighpc
  AttrLanguage
  AttrDiscr
  AttrDiscrValue
  AttrVisibility
  AttrImport
  AttrStringLength
  AttrCommonRef
  AttrCompDir
  AttrConstValue
  AttrContainingType
  AttrDefaultValue
  AttrInline
  AttrIsOptional
  AttrLowerBound
  AttrProducer
  AttrPrototyped
  AttrReturnAddr
  AttrStartScope
  AttrStrideSize
  AttrUpperBound
  AttrAbstractOrigin
  AttrAccessibility
  AttrAddrClass
  AttrArtificial
  AttrBaseTypes
  AttrCalling
  AttrCount
  AttrDataMemberLoc
  AttrDeclColumn
  AttrDeclFile
  AttrDeclLine
  AttrDeclaration
  AttrDiscrList
  AttrEncoding
  AttrExternal
  AttrFrameBase
  AttrFriend
  AttrIdentifierCase
  AttrMacroInfo
  AttrNamelistItem
  AttrPriority
  AttrSegment
  AttrSpecification
  AttrStaticLink
  AttrType
  AttrUseLocation
  AttrVarParam
  AttrVirtuality
  AttrVtableElemLoc
  // DWARF 3
  AttrAllocated
  AttrAssociated
  AttrDataLocation
  AttrStride
  AttrEntrypc
  AttrUseUTF8
  AttrExtension
  AttrRanges
  AttrTrampoline
  AttrCallColumn
  AttrCallFile
  AttrCallLine
  AttrDescription
  AttrBinaryScale
  AttrDecimalScale
  AttrSmall
  AttrDecimalSign
  AttrDigitCount
  AttrPictureString
  AttrMutable
  AttrThreadsScaled
  AttrExplicit
  AttrObjectPointer
  AttrEndianity
  AttrElemental
  AttrPure
  AttrRecursive
  // DWARF 4
  AttrSignature
  AttrMainSubprogram
  AttrDataBitOffset
  AttrConstExpr
  AttrEnumClass
  AttrLinkageName
  // DWARF 5
  AttrStringLengthBitSize
  AttrStringLengthByteSize
  AttrRank
  AttrStrOffsetsBase
  AttrAddrBase
  AttrRnglistsBase
  AttrDwoName
  AttrReference
  AttrRvalueReference
  AttrMacros
  AttrCallAllCalls
  AttrCallAllSourceCalls
  AttrCallAllTailCalls
  AttrCallReturnPC
  AttrCallValue
  AttrCallOrigin
  AttrCallParameter
  AttrCallPC
  AttrCallTailCall
  AttrCallTarget
  AttrCallTargetClobbered
  AttrCallDataLocation
  AttrCallDataValue
  AttrNoreturn
  AttrAlignment
  AttrExportSymbols
  AttrDeleted
  AttrDefaulted
  AttrLoclistsBase
} derive(Show, Eq)

///|
/// Convert Attr to its corresponding UInt value
pub fn Attr::to_uint(self : Attr) -> UInt {
  match self {
    AttrSibling => 0x01
    AttrLocation => 0x02
    AttrName => 0x03
    AttrOrdering => 0x09
    AttrByteSize => 0x0B
    AttrBitOffset => 0x0C
    AttrBitSize => 0x0D
    AttrStmtList => 0x10
    AttrLowpc => 0x11
    AttrHighpc => 0x12
    AttrLanguage => 0x13
    AttrDiscr => 0x15
    AttrDiscrValue => 0x16
    AttrVisibility => 0x17
    AttrImport => 0x18
    AttrStringLength => 0x19
    AttrCommonRef => 0x1A
    AttrCompDir => 0x1B
    AttrConstValue => 0x1C
    AttrContainingType => 0x1D
    AttrDefaultValue => 0x1E
    AttrInline => 0x20
    AttrIsOptional => 0x21
    AttrLowerBound => 0x22
    AttrProducer => 0x25
    AttrPrototyped => 0x27
    AttrReturnAddr => 0x2A
    AttrStartScope => 0x2C
    AttrStrideSize => 0x2E
    AttrUpperBound => 0x2F
    AttrAbstractOrigin => 0x31
    AttrAccessibility => 0x32
    AttrAddrClass => 0x33
    AttrArtificial => 0x34
    AttrBaseTypes => 0x35
    AttrCalling => 0x36
    AttrCount => 0x37
    AttrDataMemberLoc => 0x38
    AttrDeclColumn => 0x39
    AttrDeclFile => 0x3A
    AttrDeclLine => 0x3B
    AttrDeclaration => 0x3C
    AttrDiscrList => 0x3D
    AttrEncoding => 0x3E
    AttrExternal => 0x3F
    AttrFrameBase => 0x40
    AttrFriend => 0x41
    AttrIdentifierCase => 0x42
    AttrMacroInfo => 0x43
    AttrNamelistItem => 0x44
    AttrPriority => 0x45
    AttrSegment => 0x46
    AttrSpecification => 0x47
    AttrStaticLink => 0x48
    AttrType => 0x49
    AttrUseLocation => 0x4A
    AttrVarParam => 0x4B
    AttrVirtuality => 0x4C
    AttrVtableElemLoc => 0x4D
    AttrAllocated => 0x4E
    AttrAssociated => 0x4F
    AttrDataLocation => 0x50
    AttrStride => 0x51
    AttrEntrypc => 0x52
    AttrUseUTF8 => 0x53
    AttrExtension => 0x54
    AttrRanges => 0x55
    AttrTrampoline => 0x56
    AttrCallColumn => 0x57
    AttrCallFile => 0x58
    AttrCallLine => 0x59
    AttrDescription => 0x5A
    AttrBinaryScale => 0x5B
    AttrDecimalScale => 0x5C
    AttrSmall => 0x5D
    AttrDecimalSign => 0x5E
    AttrDigitCount => 0x5F
    AttrPictureString => 0x60
    AttrMutable => 0x61
    AttrThreadsScaled => 0x62
    AttrExplicit => 0x63
    AttrObjectPointer => 0x64
    AttrEndianity => 0x65
    AttrElemental => 0x66
    AttrPure => 0x67
    AttrRecursive => 0x68
    AttrSignature => 0x69
    AttrMainSubprogram => 0x6A
    AttrDataBitOffset => 0x6B
    AttrConstExpr => 0x6C
    AttrEnumClass => 0x6D
    AttrLinkageName => 0x6E
    AttrStringLengthBitSize => 0x6F
    AttrStringLengthByteSize => 0x70
    AttrRank => 0x71
    AttrStrOffsetsBase => 0x72
    AttrAddrBase => 0x73
    AttrRnglistsBase => 0x74
    AttrDwoName => 0x76
    AttrReference => 0x77
    AttrRvalueReference => 0x78
    AttrMacros => 0x79
    AttrCallAllCalls => 0x7A
    AttrCallAllSourceCalls => 0x7B
    AttrCallAllTailCalls => 0x7C
    AttrCallReturnPC => 0x7D
    AttrCallValue => 0x7E
    AttrCallOrigin => 0x7F
    AttrCallParameter => 0x80
    AttrCallPC => 0x81
    AttrCallTailCall => 0x82
    AttrCallTarget => 0x83
    AttrCallTargetClobbered => 0x84
    AttrCallDataLocation => 0x85
    AttrCallDataValue => 0x86
    AttrNoreturn => 0x87
    AttrAlignment => 0x88
    AttrExportSymbols => 0x89
    AttrDeleted => 0x8A
    AttrDefaulted => 0x8B
    AttrLoclistsBase => 0x8C
    Attr(val) => val
  }
}

///|
/// Convert UInt to Format
fn Format::from_uint(val : UInt) -> Format {
  match val {
    0x01 => FormAddr
    0x03 => FormDwarfBlock2
    0x04 => FormDwarfBlock4
    0x05 => FormData2
    0x06 => FormData4
    0x07 => FormData8
    0x08 => FormString
    0x09 => FormDwarfBlock
    0x0A => FormDwarfBlock1
    0x0B => FormData1
    0x0C => FormFlag
    0x0D => FormSdata
    0x0E => FormStrp
    0x0F => FormUdata
    0x10 => FormRefAddr
    0x11 => FormRef1
    0x12 => FormRef2
    0x13 => FormRef4
    0x14 => FormRef8
    0x15 => FormRefUdata
    0x16 => FormIndirect
    0x17 => FormSecOffset
    0x18 => FormExprloc
    0x19 => FormFlagPresent
    0x20 => FormRefSig8
    0x1A => FormStrx
    0x1B => FormAddrx
    0x1C => FormRefSup4
    0x1D => FormStrpSup
    0x1E => FormData16
    0x1F => FormLineStrp
    0x21 => FormImplicitConst
    0x22 => FormLoclistx
    0x23 => FormRnglistx
    0x24 => FormRefSup8
    0x25 => FormStrx1
    0x26 => FormStrx2
    0x27 => FormStrx3
    0x28 => FormStrx4
    0x29 => FormAddrx1
    0x2A => FormAddrx2
    0x2B => FormAddrx3
    0x2C => FormAddrx4
    0x1F20 => FormGnuRefAlt
    0x1F21 => FormGnuStrpAlt
    val => Format(val)
  }
}

///|
/// Convert UInt to Tag
pub fn Tag::from_uint(val : UInt) -> Tag? {
  match val {
    0x01 => Some(TagArrayType)
    0x02 => Some(TagClassType)
    0x03 => Some(TagEntryPoint)
    0x04 => Some(TagEnumerationType)
    0x05 => Some(TagFormalParameter)
    0x08 => Some(TagImportedDeclaration)
    0x0A => Some(TagLabel)
    0x0B => Some(TagLexDwarfBlock)
    0x0D => Some(TagMember)
    0x0F => Some(TagPointerType)
    0x10 => Some(TagReferenceType)
    0x11 => Some(TagCompileUnit)
    0x12 => Some(TagStringType)
    0x13 => Some(TagStructType)
    0x15 => Some(TagSubroutineType)
    0x16 => Some(TagTypedef)
    0x17 => Some(TagUnionType)
    0x18 => Some(TagUnspecifiedParameters)
    0x19 => Some(TagVariant)
    0x1A => Some(TagCommonDwarfBlock)
    0x1B => Some(TagCommonInclusion)
    0x1C => Some(TagInheritance)
    0x1D => Some(TagInlinedSubroutine)
    0x1E => Some(TagModule)
    0x1F => Some(TagPtrToMemberType)
    0x20 => Some(TagSetType)
    0x21 => Some(TagSubrangeType)
    0x22 => Some(TagWithStmt)
    0x23 => Some(TagAccessDeclaration)
    0x24 => Some(TagBaseType)
    0x25 => Some(TagCatchDwarfBlock)
    0x26 => Some(TagConstType)
    0x27 => Some(TagConstant)
    0x28 => Some(TagEnumerator)
    0x29 => Some(TagFileType)
    0x2A => Some(TagFriend)
    0x2B => Some(TagNamelist)
    0x2C => Some(TagNamelistItem)
    0x2D => Some(TagPackedType)
    0x2E => Some(TagSubprogram)
    0x2F => Some(TagTemplateTypeParameter)
    0x30 => Some(TagTemplateValueParameter)
    0x31 => Some(TagThrownType)
    0x32 => Some(TagTryDwarfBlock)
    0x33 => Some(TagVariantPart)
    0x34 => Some(TagVariable)
    0x35 => Some(TagVolatileType)
    0x36 => Some(TagDwarfProcedure)
    0x37 => Some(TagRestrictType)
    0x38 => Some(TagInterfaceType)
    0x39 => Some(TagNamespace)
    0x3A => Some(TagImportedModule)
    0x3B => Some(TagUnspecifiedType)
    0x3C => Some(TagPartialUnit)
    0x3D => Some(TagImportedUnit)
    0x3E => Some(TagMutableType)
    0x3F => Some(TagCondition)
    0x40 => Some(TagSharedType)
    0x41 => Some(TagTypeUnit)
    0x42 => Some(TagRvalueReferenceType)
    0x43 => Some(TagTemplateAlias)
    0x44 => Some(TagCoarrayType)
    0x45 => Some(TagGenericSubrange)
    0x46 => Some(TagDynamicType)
    0x47 => Some(TagAtomicType)
    0x48 => Some(TagCallSite)
    0x49 => Some(TagCallSiteParameter)
    0x4A => Some(TagSkeletonUnit)
    0x4B => Some(TagImmutableType)
    _ => None
  }
}

///|
/// Convert UInt to Attr
pub fn Attr::from_uint(val : UInt) -> Attr {
  match val {
    0x01 => AttrSibling
    0x02 => AttrLocation
    0x03 => AttrName
    0x09 => AttrOrdering
    0x0B => AttrByteSize
    0x0C => AttrBitOffset
    0x0D => AttrBitSize
    0x10 => AttrStmtList
    0x11 => AttrLowpc
    0x12 => AttrHighpc
    0x13 => AttrLanguage
    0x15 => AttrDiscr
    0x16 => AttrDiscrValue
    0x17 => AttrVisibility
    0x18 => AttrImport
    0x19 => AttrStringLength
    0x1A => AttrCommonRef
    0x1B => AttrCompDir
    0x1C => AttrConstValue
    0x1D => AttrContainingType
    0x1E => AttrDefaultValue
    0x20 => AttrInline
    0x21 => AttrIsOptional
    0x22 => AttrLowerBound
    0x25 => AttrProducer
    0x27 => AttrPrototyped
    0x2A => AttrReturnAddr
    0x2C => AttrStartScope
    0x2E => AttrStrideSize
    0x2F => AttrUpperBound
    0x31 => AttrAbstractOrigin
    0x32 => AttrAccessibility
    0x33 => AttrAddrClass
    0x34 => AttrArtificial
    0x35 => AttrBaseTypes
    0x36 => AttrCalling
    0x37 => AttrCount
    0x38 => AttrDataMemberLoc
    0x39 => AttrDeclColumn
    0x3A => AttrDeclFile
    0x3B => AttrDeclLine
    0x3C => AttrDeclaration
    0x3D => AttrDiscrList
    0x3E => AttrEncoding
    0x3F => AttrExternal
    0x40 => AttrFrameBase
    0x41 => AttrFriend
    0x42 => AttrIdentifierCase
    0x43 => AttrMacroInfo
    0x44 => AttrNamelistItem
    0x45 => AttrPriority
    0x46 => AttrSegment
    0x47 => AttrSpecification
    0x48 => AttrStaticLink
    0x49 => AttrType
    0x4A => AttrUseLocation
    0x4B => AttrVarParam
    0x4C => AttrVirtuality
    0x4D => AttrVtableElemLoc
    0x4E => AttrAllocated
    0x4F => AttrAssociated
    0x50 => AttrDataLocation
    0x51 => AttrStride
    0x52 => AttrEntrypc
    0x53 => AttrUseUTF8
    0x54 => AttrExtension
    0x55 => AttrRanges
    0x56 => AttrTrampoline
    0x57 => AttrCallColumn
    0x58 => AttrCallFile
    0x59 => AttrCallLine
    0x5A => AttrDescription
    0x5B => AttrBinaryScale
    0x5C => AttrDecimalScale
    0x5D => AttrSmall
    0x5E => AttrDecimalSign
    0x5F => AttrDigitCount
    0x60 => AttrPictureString
    0x61 => AttrMutable
    0x62 => AttrThreadsScaled
    0x63 => AttrExplicit
    0x64 => AttrObjectPointer
    0x65 => AttrEndianity
    0x66 => AttrElemental
    0x67 => AttrPure
    0x68 => AttrRecursive
    0x69 => AttrSignature
    0x6A => AttrMainSubprogram
    0x6B => AttrDataBitOffset
    0x6C => AttrConstExpr
    0x6D => AttrEnumClass
    0x6E => AttrLinkageName
    0x6F => AttrStringLengthBitSize
    0x70 => AttrStringLengthByteSize
    0x71 => AttrRank
    0x72 => AttrStrOffsetsBase
    0x73 => AttrAddrBase
    0x74 => AttrRnglistsBase
    0x76 => AttrDwoName
    0x77 => AttrReference
    0x78 => AttrRvalueReference
    0x79 => AttrMacros
    0x7A => AttrCallAllCalls
    0x7B => AttrCallAllSourceCalls
    0x7C => AttrCallAllTailCalls
    0x7D => AttrCallReturnPC
    0x7E => AttrCallValue
    0x7F => AttrCallOrigin
    0x80 => AttrCallParameter
    0x81 => AttrCallPC
    0x82 => AttrCallTailCall
    0x83 => AttrCallTarget
    0x84 => AttrCallTargetClobbered
    0x85 => AttrCallDataLocation
    0x86 => AttrCallDataValue
    0x87 => AttrNoreturn
    0x88 => AttrAlignment
    0x89 => AttrExportSymbols
    0x8A => AttrDeleted
    0x8B => AttrDefaulted
    0x8C => AttrLoclistsBase
    val => Attr(val)
  }
}

///|
/// A format is a DWARF data encoding format.
pub enum Format {
  // Value formats
  FormAddr
  FormDwarfBlock2
  FormDwarfBlock4
  FormData2
  FormData4
  FormData8
  FormString
  FormDwarfBlock
  FormDwarfBlock1
  FormData1
  FormFlag
  FormSdata
  FormStrp
  FormUdata
  FormRefAddr
  FormRef1
  FormRef2
  FormRef4
  FormRef8
  FormRefUdata
  FormIndirect
  // DWARF 4
  FormSecOffset
  FormExprloc
  FormFlagPresent
  FormRefSig8
  // DWARF 5
  FormStrx
  FormAddrx
  FormRefSup4
  FormStrpSup
  FormData16
  FormLineStrp
  FormImplicitConst
  FormLoclistx
  FormRnglistx
  FormRefSup8
  FormStrx1
  FormStrx2
  FormStrx3
  FormStrx4
  FormAddrx1
  FormAddrx2
  FormAddrx3
  FormAddrx4
  // Extensions for multi-file compression (.dwz)
  FormGnuRefAlt
  FormGnuStrpAlt
  Format(UInt)
} derive(Show, Eq)

///|
/// A Tag is the classification (the type) of an Entry.
pub enum Tag {
  TagArrayType
  TagClassType
  TagEntryPoint
  TagEnumerationType
  TagFormalParameter
  TagImportedDeclaration
  TagLabel
  TagLexDwarfBlock
  TagMember
  TagPointerType
  TagReferenceType
  TagCompileUnit
  TagStringType
  TagStructType
  TagSubroutineType
  TagTypedef
  TagUnionType
  TagUnspecifiedParameters
  TagVariant
  TagCommonDwarfBlock
  TagCommonInclusion
  TagInheritance
  TagInlinedSubroutine
  TagModule
  TagPtrToMemberType
  TagSetType
  TagSubrangeType
  TagWithStmt
  TagAccessDeclaration
  TagBaseType
  TagCatchDwarfBlock
  TagConstType
  TagConstant
  TagEnumerator
  TagFileType
  TagFriend
  TagNamelist
  TagNamelistItem
  TagPackedType
  TagSubprogram
  TagTemplateTypeParameter
  TagTemplateValueParameter
  TagThrownType
  TagTryDwarfBlock
  TagVariantPart
  TagVariable
  TagVolatileType
  // DWARF 3
  TagDwarfProcedure
  TagRestrictType
  TagInterfaceType
  TagNamespace
  TagImportedModule
  TagUnspecifiedType
  TagPartialUnit
  TagImportedUnit
  TagMutableType
  TagCondition
  TagSharedType
  // DWARF 4
  TagTypeUnit
  TagRvalueReferenceType
  TagTemplateAlias
  // DWARF 5
  TagCoarrayType
  TagGenericSubrange
  TagDynamicType
  TagAtomicType
  TagCallSite
  TagCallSiteParameter
  TagSkeletonUnit
  TagImmutableType
  Tag(UInt)
} derive(Show, Eq)

///|
/// Convert Tag to its corresponding UInt value
pub fn Tag::to_uint(self : Tag) -> UInt {
  match self {
    TagArrayType => 0x01
    TagClassType => 0x02
    TagEntryPoint => 0x03
    TagEnumerationType => 0x04
    TagFormalParameter => 0x05
    TagImportedDeclaration => 0x08
    TagLabel => 0x0A
    TagLexDwarfBlock => 0x0B
    TagMember => 0x0D
    TagPointerType => 0x0F
    TagReferenceType => 0x10
    TagCompileUnit => 0x11
    TagStringType => 0x12
    TagStructType => 0x13
    TagSubroutineType => 0x15
    TagTypedef => 0x16
    TagUnionType => 0x17
    TagUnspecifiedParameters => 0x18
    TagVariant => 0x19
    TagCommonDwarfBlock => 0x1A
    TagCommonInclusion => 0x1B
    TagInheritance => 0x1C
    TagInlinedSubroutine => 0x1D
    TagModule => 0x1E
    TagPtrToMemberType => 0x1F
    TagSetType => 0x20
    TagSubrangeType => 0x21
    TagWithStmt => 0x22
    TagAccessDeclaration => 0x23
    TagBaseType => 0x24
    TagCatchDwarfBlock => 0x25
    TagConstType => 0x26
    TagConstant => 0x27
    TagEnumerator => 0x28
    TagFileType => 0x29
    TagFriend => 0x2A
    TagNamelist => 0x2B
    TagNamelistItem => 0x2C
    TagPackedType => 0x2D
    TagSubprogram => 0x2E
    TagTemplateTypeParameter => 0x2F
    TagTemplateValueParameter => 0x30
    TagThrownType => 0x31
    TagTryDwarfBlock => 0x32
    TagVariantPart => 0x33
    TagVariable => 0x34
    TagVolatileType => 0x35
    TagDwarfProcedure => 0x36
    TagRestrictType => 0x37
    TagInterfaceType => 0x38
    TagNamespace => 0x39
    TagImportedModule => 0x3A
    TagUnspecifiedType => 0x3B
    TagPartialUnit => 0x3C
    TagImportedUnit => 0x3D
    TagMutableType => 0x3E
    TagCondition => 0x3F
    TagSharedType => 0x40
    TagTypeUnit => 0x41
    TagRvalueReferenceType => 0x42
    TagTemplateAlias => 0x43
    TagCoarrayType => 0x44
    TagGenericSubrange => 0x45
    TagDynamicType => 0x46
    TagAtomicType => 0x47
    TagCallSite => 0x48
    TagCallSiteParameter => 0x49
    TagSkeletonUnit => 0x4A
    TagImmutableType => 0x4B
    Tag(tag) => tag
  }
}

///|
/// Location expression operators
/// The debug info encodes value locations like 8(R3) as a sequence of these op codes.
const OpAddr : UInt = 0x03

///|
const OpDeref : UInt = 0x06

///|
const OpConst1u : UInt = 0x08

///|
const OpConst1s : UInt = 0x09

///|
const OpConst2u : UInt = 0x0A

///|
const OpConst2s : UInt = 0x0B

///|
const OpConst4u : UInt = 0x0C

///|
const OpConst4s : UInt = 0x0D

///|
const OpConst8u : UInt = 0x0E

///|
const OpConst8s : UInt = 0x0F

///|
const OpConstu : UInt = 0x10

///|
const OpConsts : UInt = 0x11

///|
const OpDup : UInt = 0x12

///|
const OpDrop : UInt = 0x13

///|
const OpOver : UInt = 0x14

///|
const OpPick : UInt = 0x15

///|
const OpSwap : UInt = 0x16

///|
const OpRot : UInt = 0x17

///|
const OpXderef : UInt = 0x18

///|
const OpAbs : UInt = 0x19

///|
const OpAnd : UInt = 0x1A

///|
const OpDiv : UInt = 0x1B

///|
const OpMinus : UInt = 0x1C

///|
const OpMod : UInt = 0x1D

///|
const OpMul : UInt = 0x1E

///|
const OpNeg : UInt = 0x1F

///|
const OpNot : UInt = 0x20

///|
const OpOr : UInt = 0x21

///|
const OpPlus : UInt = 0x22

///|
const OpPlusUconst : UInt = 0x23

///|
const OpShl : UInt = 0x24

///|
const OpShr : UInt = 0x25

///|
const OpShra : UInt = 0x26

///|
const OpXor : UInt = 0x27

///|
const OpSkip : UInt = 0x2F

///|
const OpBra : UInt = 0x28

///|
const OpEq : UInt = 0x29

///|
const OpGe : UInt = 0x2A

///|
const OpGt : UInt = 0x2B

///|
const OpLe : UInt = 0x2C

///|
const OpLt : UInt = 0x2D

///|
const OpNe : UInt = 0x2E

///|
const OpLit0 : UInt = 0x30

///|
const OpReg0 : UInt = 0x50

///|
const OpBreg0 : UInt = 0x70

///|
const OpRegx : UInt = 0x90

///|
const OpFbreg : UInt = 0x91

///|
const OpBregx : UInt = 0x92

///|
const OpPiece : UInt = 0x93

///|
const OpDerefSize : UInt = 0x94

///|
const OpXderefSize : UInt = 0x95

///|
const OpNop : UInt = 0x96
/// DWARF 3

///|
const OpPushObjAddr : UInt = 0x97

///|
const OpCall2 : UInt = 0x98

///|
const OpCall4 : UInt = 0x99

///|
const OpCallRef : UInt = 0x9A

///|
const OpFormTlsAddress : UInt = 0x9B

///|
const OpCallFrameCfa : UInt = 0x9C

///|
const OpBitPiece : UInt = 0x9D
/// DWARF 4

///|
const OpImplicitValue : UInt = 0x9E

///|
const OpStackValue : UInt = 0x9F
/// DWARF 5

///|
const OpImplicitPointer : UInt = 0xA0

///|
const OpAddrx : UInt = 0xA1

///|
const OpConstx : UInt = 0xA2

///|
const OpEntryValue : UInt = 0xA3

///|
const OpConstType : UInt = 0xA4

///|
const OpRegvalType : UInt = 0xA5

///|
const OpDerefType : UInt = 0xA6

///|
const OpXderefType : UInt = 0xA7

///|
const OpConvert : UInt = 0xA8

///|
const OpReinterpret : UInt = 0xA9

///|
/// Basic type encodings -- the value for AttrEncoding in a TagBaseType Entry.
const EncAddress : Int64 = 0x01

///|
const EncBoolean : Int64 = 0x02

///|
const EncComplexFloat : Int64 = 0x03

///|
const EncFloat : Int64 = 0x04

///|
const EncSigned : Int64 = 0x05

///|
const EncSignedChar : Int64 = 0x06

///|
const EncUnsigned : Int64 = 0x07

///|
const EncUnsignedChar : Int64 = 0x08
/// DWARF 3

///|
const EncImaginaryFloat : Int64 = 0x09

///|
const EncPackedDecimal : Int64 = 0x0A

///|
const EncNumericString : Int64 = 0x0B

///|
const EncEdited : Int64 = 0x0C

///|
const EncSignedFixed : Int64 = 0x0D

///|
const EncUnsignedFixed : Int64 = 0x0E

///|
const EncDecimalFloat : Int64 = 0x0F
/// DWARF 4

///|
const EncUtf : Int64 = 0x10
/// DWARF 5

///|
const EncUcs : Int64 = 0x11

///|
const EncAscii : Int64 = 0x12

///|
/// Statement program standard opcode encodings.
const LnsCopy : UInt = 1

///|
const LnsAdvancePc : UInt = 2

///|
const LnsAdvanceLine : UInt = 3

///|
const LnsSetFile : UInt = 4

///|
const LnsSetColumn : UInt = 5

///|
const LnsNegateStmt : UInt = 6

///|
const LnsSetBasicBlock : UInt = 7

///|
const LnsConstAddPc : UInt = 8

///|
const LnsFixedAdvancePc : UInt = 9
/// DWARF 3

///|
const LnsSetPrologueEnd : UInt = 10

///|
const LnsSetEpilogueBegin : UInt = 11

///|
const LnsSetISA : UInt = 12

///|
/// Statement program extended opcode encodings.
const LneEndSequence : UInt = 1

///|
const LneSetAddress : UInt = 2

///|
const LneDefineFile : UInt = 3
/// DWARF 4

///|
const LneSetDiscriminator : UInt = 4

///|
/// Line table directory and file name entry formats.
/// These are new in DWARF 5.
const LnctPath : UInt = 0x01U

///|
const LnctDirectoryIndex : UInt = 0x02

///|
const LnctTimestamp : UInt = 0x03

///|
const LnctSize : UInt = 0x04

///|
const LnctMD5 : UInt = 0x05

///|
/// Location list entry codes.
/// These are new in DWARF 5.
const LleEndOfList : UInt = 0x00

///|
const LleBaseAddressx : UInt = 0x01

///|
const LleStartxEndx : UInt = 0x02

///|
const LleStartxLength : UInt = 0x03

///|
const LleOffsetPair : UInt = 0x04

///|
const LleDefaultLocation : UInt = 0x05

///|
const LleBaseAddress : UInt = 0x06

///|
const LleStartEnd : UInt = 0x07

///|
const LleStartLength : UInt = 0x08U

///|
/// Unit header unit type encodings.
/// These are new in DWARF 5.
const UtCompile : UInt = 0x01

///|
const UtType : UInt = 0x02

///|
const UtPartial : UInt = 0x03

///|
const UtSkeleton : UInt = 0x04

///|
const UtSplitCompile : UInt = 0x05

///|
const UtSplitType : UInt = 0x06

///|
/// Opcodes for DWARFv5 debug_rnglists section.
const RleEndOfList : UInt = 0x0

///|
const RleBaseAddressx : UInt = 0x1

///|
const RleStartxEndx : UInt = 0x2

///|
const RleStartxLength : UInt = 0x3

///|
const RleOffsetPair : UInt = 0x4

///|
const RleBaseAddress : UInt = 0x5

///|
const RleStartEnd : UInt = 0x6

///|
const RleStartLength : UInt = 0x7
