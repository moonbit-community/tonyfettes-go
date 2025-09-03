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
    0x01U => FormAddr
    0x03U => FormDwarfBlock2
    0x04U => FormDwarfBlock4
    0x05U => FormData2
    0x06U => FormData4
    0x07U => FormData8
    0x08U => FormString
    0x09U => FormDwarfBlock
    0x0AU => FormDwarfBlock1
    0x0BU => FormData1
    0x0CU => FormFlag
    0x0DU => FormSdata
    0x0EU => FormStrp
    0x0FU => FormUdata
    0x10U => FormRefAddr
    0x11U => FormRef1
    0x12U => FormRef2
    0x13U => FormRef4
    0x14U => FormRef8
    0x15U => FormRefUdata
    0x16U => FormIndirect
    0x17U => FormSecOffset
    0x18U => FormExprloc
    0x19U => FormFlagPresent
    0x20U => FormRefSig8
    0x1AU => FormStrx
    0x1BU => FormAddrx
    0x1CU => FormRefSup4
    0x1DU => FormStrpSup
    0x1EU => FormData16
    0x1FU => FormLineStrp
    0x21U => FormImplicitConst
    0x22U => FormLoclistx
    0x23U => FormRnglistx
    0x24U => FormRefSup8
    0x25U => FormStrx1
    0x26U => FormStrx2
    0x27U => FormStrx3
    0x28U => FormStrx4
    0x29U => FormAddrx1
    0x2AU => FormAddrx2
    0x2BU => FormAddrx3
    0x2CU => FormAddrx4
    0x1F20U => FormGnuRefAlt
    0x1F21U => FormGnuStrpAlt
    val => Format(val)
  }
}

///|
/// Convert UInt to Tag
pub fn Tag::from_uint(val : UInt) -> Tag? {
  match val {
    0x01U => Some(TagArrayType)
    0x02U => Some(TagClassType)
    0x03U => Some(TagEntryPoint)
    0x04U => Some(TagEnumerationType)
    0x05U => Some(TagFormalParameter)
    0x08U => Some(TagImportedDeclaration)
    0x0AU => Some(TagLabel)
    0x0BU => Some(TagLexDwarfBlock)
    0x0DU => Some(TagMember)
    0x0FU => Some(TagPointerType)
    0x10U => Some(TagReferenceType)
    0x11U => Some(TagCompileUnit)
    0x12U => Some(TagStringType)
    0x13U => Some(TagStructType)
    0x15U => Some(TagSubroutineType)
    0x16U => Some(TagTypedef)
    0x17U => Some(TagUnionType)
    0x18U => Some(TagUnspecifiedParameters)
    0x19U => Some(TagVariant)
    0x1AU => Some(TagCommonDwarfBlock)
    0x1BU => Some(TagCommonInclusion)
    0x1CU => Some(TagInheritance)
    0x1DU => Some(TagInlinedSubroutine)
    0x1EU => Some(TagModule)
    0x1FU => Some(TagPtrToMemberType)
    0x20U => Some(TagSetType)
    0x21U => Some(TagSubrangeType)
    0x22U => Some(TagWithStmt)
    0x23U => Some(TagAccessDeclaration)
    0x24U => Some(TagBaseType)
    0x25U => Some(TagCatchDwarfBlock)
    0x26U => Some(TagConstType)
    0x27U => Some(TagConstant)
    0x28U => Some(TagEnumerator)
    0x29U => Some(TagFileType)
    0x2AU => Some(TagFriend)
    0x2BU => Some(TagNamelist)
    0x2CU => Some(TagNamelistItem)
    0x2DU => Some(TagPackedType)
    0x2EU => Some(TagSubprogram)
    0x2FU => Some(TagTemplateTypeParameter)
    0x30U => Some(TagTemplateValueParameter)
    0x31U => Some(TagThrownType)
    0x32U => Some(TagTryDwarfBlock)
    0x33U => Some(TagVariantPart)
    0x34U => Some(TagVariable)
    0x35U => Some(TagVolatileType)
    0x36U => Some(TagDwarfProcedure)
    0x37U => Some(TagRestrictType)
    0x38U => Some(TagInterfaceType)
    0x39U => Some(TagNamespace)
    0x3AU => Some(TagImportedModule)
    0x3BU => Some(TagUnspecifiedType)
    0x3CU => Some(TagPartialUnit)
    0x3DU => Some(TagImportedUnit)
    0x3EU => Some(TagMutableType)
    0x3FU => Some(TagCondition)
    0x40U => Some(TagSharedType)
    0x41U => Some(TagTypeUnit)
    0x42U => Some(TagRvalueReferenceType)
    0x43U => Some(TagTemplateAlias)
    0x44U => Some(TagCoarrayType)
    0x45U => Some(TagGenericSubrange)
    0x46U => Some(TagDynamicType)
    0x47U => Some(TagAtomicType)
    0x48U => Some(TagCallSite)
    0x49U => Some(TagCallSiteParameter)
    0x4AU => Some(TagSkeletonUnit)
    0x4BU => Some(TagImmutableType)
    _ => None
  }
}

///|
/// Convert UInt to Attr
pub fn Attr::from_uint(val : UInt) -> Attr {
  match val {
    0x01U => AttrSibling
    0x02U => AttrLocation
    0x03U => AttrName
    0x09U => AttrOrdering
    0x0BU => AttrByteSize
    0x0CU => AttrBitOffset
    0x0DU => AttrBitSize
    0x10U => AttrStmtList
    0x11U => AttrLowpc
    0x12U => AttrHighpc
    0x13U => AttrLanguage
    0x15U => AttrDiscr
    0x16U => AttrDiscrValue
    0x17U => AttrVisibility
    0x18U => AttrImport
    0x19U => AttrStringLength
    0x1AU => AttrCommonRef
    0x1BU => AttrCompDir
    0x1CU => AttrConstValue
    0x1DU => AttrContainingType
    0x1EU => AttrDefaultValue
    0x20U => AttrInline
    0x21U => AttrIsOptional
    0x22U => AttrLowerBound
    0x25U => AttrProducer
    0x27U => AttrPrototyped
    0x2AU => AttrReturnAddr
    0x2CU => AttrStartScope
    0x2EU => AttrStrideSize
    0x2FU => AttrUpperBound
    0x31U => AttrAbstractOrigin
    0x32U => AttrAccessibility
    0x33U => AttrAddrClass
    0x34U => AttrArtificial
    0x35U => AttrBaseTypes
    0x36U => AttrCalling
    0x37U => AttrCount
    0x38U => AttrDataMemberLoc
    0x39U => AttrDeclColumn
    0x3AU => AttrDeclFile
    0x3BU => AttrDeclLine
    0x3CU => AttrDeclaration
    0x3DU => AttrDiscrList
    0x3EU => AttrEncoding
    0x3FU => AttrExternal
    0x40U => AttrFrameBase
    0x41U => AttrFriend
    0x42U => AttrIdentifierCase
    0x43U => AttrMacroInfo
    0x44U => AttrNamelistItem
    0x45U => AttrPriority
    0x46U => AttrSegment
    0x47U => AttrSpecification
    0x48U => AttrStaticLink
    0x49U => AttrType
    0x4AU => AttrUseLocation
    0x4BU => AttrVarParam
    0x4CU => AttrVirtuality
    0x4DU => AttrVtableElemLoc
    0x4EU => AttrAllocated
    0x4FU => AttrAssociated
    0x50U => AttrDataLocation
    0x51U => AttrStride
    0x52U => AttrEntrypc
    0x53U => AttrUseUTF8
    0x54U => AttrExtension
    0x55U => AttrRanges
    0x56U => AttrTrampoline
    0x57U => AttrCallColumn
    0x58U => AttrCallFile
    0x59U => AttrCallLine
    0x5AU => AttrDescription
    0x5BU => AttrBinaryScale
    0x5CU => AttrDecimalScale
    0x5DU => AttrSmall
    0x5EU => AttrDecimalSign
    0x5FU => AttrDigitCount
    0x60U => AttrPictureString
    0x61U => AttrMutable
    0x62U => AttrThreadsScaled
    0x63U => AttrExplicit
    0x64U => AttrObjectPointer
    0x65U => AttrEndianity
    0x66U => AttrElemental
    0x67U => AttrPure
    0x68U => AttrRecursive
    0x69U => AttrSignature
    0x6AU => AttrMainSubprogram
    0x6BU => AttrDataBitOffset
    0x6CU => AttrConstExpr
    0x6DU => AttrEnumClass
    0x6EU => AttrLinkageName
    0x6FU => AttrStringLengthBitSize
    0x70U => AttrStringLengthByteSize
    0x71U => AttrRank
    0x72U => AttrStrOffsetsBase
    0x73U => AttrAddrBase
    0x74U => AttrRnglistsBase
    0x76U => AttrDwoName
    0x77U => AttrReference
    0x78U => AttrRvalueReference
    0x79U => AttrMacros
    0x7AU => AttrCallAllCalls
    0x7BU => AttrCallAllSourceCalls
    0x7CU => AttrCallAllTailCalls
    0x7DU => AttrCallReturnPC
    0x7EU => AttrCallValue
    0x7FU => AttrCallOrigin
    0x80U => AttrCallParameter
    0x81U => AttrCallPC
    0x82U => AttrCallTailCall
    0x83U => AttrCallTarget
    0x84U => AttrCallTargetClobbered
    0x85U => AttrCallDataLocation
    0x86U => AttrCallDataValue
    0x87U => AttrNoreturn
    0x88U => AttrAlignment
    0x89U => AttrExportSymbols
    0x8AU => AttrDeleted
    0x8BU => AttrDefaulted
    0x8CU => AttrLoclistsBase
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
const OpAddr : UInt = 0x03U

///|
const OpDeref : UInt = 0x06U

///|
const OpConst1u : UInt = 0x08U

///|
const OpConst1s : UInt = 0x09U

///|
const OpConst2u : UInt = 0x0AU

///|
const OpConst2s : UInt = 0x0BU

///|
const OpConst4u : UInt = 0x0CU

///|
const OpConst4s : UInt = 0x0DU

///|
const OpConst8u : UInt = 0x0EU

///|
const OpConst8s : UInt = 0x0FU

///|
const OpConstu : UInt = 0x10U

///|
const OpConsts : UInt = 0x11U

///|
const OpDup : UInt = 0x12U

///|
const OpDrop : UInt = 0x13U

///|
const OpOver : UInt = 0x14U

///|
const OpPick : UInt = 0x15U

///|
const OpSwap : UInt = 0x16U

///|
const OpRot : UInt = 0x17U

///|
const OpXderef : UInt = 0x18U

///|
const OpAbs : UInt = 0x19U

///|
const OpAnd : UInt = 0x1AU

///|
const OpDiv : UInt = 0x1BU

///|
const OpMinus : UInt = 0x1CU

///|
const OpMod : UInt = 0x1DU

///|
const OpMul : UInt = 0x1EU

///|
const OpNeg : UInt = 0x1FU

///|
const OpNot : UInt = 0x20U

///|
const OpOr : UInt = 0x21U

///|
const OpPlus : UInt = 0x22U

///|
const OpPlusUconst : UInt = 0x23U

///|
const OpShl : UInt = 0x24U

///|
const OpShr : UInt = 0x25U

///|
const OpShra : UInt = 0x26U

///|
const OpXor : UInt = 0x27U

///|
const OpSkip : UInt = 0x2FU

///|
const OpBra : UInt = 0x28U

///|
const OpEq : UInt = 0x29U

///|
const OpGe : UInt = 0x2AU

///|
const OpGt : UInt = 0x2BU

///|
const OpLe : UInt = 0x2CU

///|
const OpLt : UInt = 0x2DU

///|
const OpNe : UInt = 0x2EU

///|
const OpLit0 : UInt = 0x30U

///|
const OpReg0 : UInt = 0x50U

///|
const OpBreg0 : UInt = 0x70U

///|
const OpRegx : UInt = 0x90U

///|
const OpFbreg : UInt = 0x91U

///|
const OpBregx : UInt = 0x92U

///|
const OpPiece : UInt = 0x93U

///|
const OpDerefSize : UInt = 0x94U

///|
const OpXderefSize : UInt = 0x95U

///|
const OpNop : UInt = 0x96U
/// DWARF 3

///|
const OpPushObjAddr : UInt = 0x97U

///|
const OpCall2 : UInt = 0x98U

///|
const OpCall4 : UInt = 0x99U

///|
const OpCallRef : UInt = 0x9AU

///|
const OpFormTlsAddress : UInt = 0x9BU

///|
const OpCallFrameCfa : UInt = 0x9CU

///|
const OpBitPiece : UInt = 0x9DU
/// DWARF 4

///|
const OpImplicitValue : UInt = 0x9EU

///|
const OpStackValue : UInt = 0x9FU
/// DWARF 5

///|
const OpImplicitPointer : UInt = 0xA0U

///|
const OpAddrx : UInt = 0xA1U

///|
const OpConstx : UInt = 0xA2U

///|
const OpEntryValue : UInt = 0xA3U

///|
const OpConstType : UInt = 0xA4U

///|
const OpRegvalType : UInt = 0xA5U

///|
const OpDerefType : UInt = 0xA6U

///|
const OpXderefType : UInt = 0xA7U

///|
const OpConvert : UInt = 0xA8U

///|
const OpReinterpret : UInt = 0xA9U

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
const LnsCopy : UInt = 1U

///|
const LnsAdvancePc : UInt = 2U

///|
const LnsAdvanceLine : UInt = 3U

///|
const LnsSetFile : UInt = 4U

///|
const LnsSetColumn : UInt = 5U

///|
const LnsNegateStmt : UInt = 6U

///|
const LnsSetBasicBlock : UInt = 7U

///|
const LnsConstAddPc : UInt = 8U

///|
const LnsFixedAdvancePc : UInt = 9U
/// DWARF 3

///|
const LnsSetPrologueEnd : UInt = 10U

///|
const LnsSetEpilogueBegin : UInt = 11U

///|
const LnsSetISA : UInt = 12U

///|
/// Statement program extended opcode encodings.
const LneEndSequence : UInt = 1U

///|
const LneSetAddress : UInt = 2U

///|
const LneDefineFile : UInt = 3U
/// DWARF 4

///|
const LneSetDiscriminator : UInt = 4U

///|
/// Line table directory and file name entry formats.
/// These are new in DWARF 5.
const LnctPath : UInt = 0x01U

///|
const LnctDirectoryIndex : UInt = 0x02U

///|
const LnctTimestamp : UInt = 0x03U

///|
const LnctSize : UInt = 0x04U

///|
const LnctMD5 : UInt = 0x05U

///|
/// Location list entry codes.
/// These are new in DWARF 5.
const LleEndOfList : UInt = 0x00U

///|
const LleBaseAddressx : UInt = 0x01U

///|
const LleStartxEndx : UInt = 0x02U

///|
const LleStartxLength : UInt = 0x03U

///|
const LleOffsetPair : UInt = 0x04U

///|
const LleDefaultLocation : UInt = 0x05U

///|
const LleBaseAddress : UInt = 0x06U

///|
const LleStartEnd : UInt = 0x07U

///|
const LleStartLength : UInt = 0x08U

///|
/// Unit header unit type encodings.
/// These are new in DWARF 5.
const UtCompile : UInt = 0x01U

///|
const UtType : UInt = 0x02U

///|
const UtPartial : UInt = 0x03U

///|
const UtSkeleton : UInt = 0x04U

///|
const UtSplitCompile : UInt = 0x05U

///|
const UtSplitType : UInt = 0x06U

///|
/// Opcodes for DWARFv5 debug_rnglists section.
const RleEndOfList : UInt = 0x0U

///|
const RleBaseAddressx : UInt = 0x1U

///|
const RleStartxEndx : UInt = 0x2U

///|
const RleStartxLength : UInt = 0x3U

///|
const RleOffsetPair : UInt = 0x4U

///|
const RleBaseAddress : UInt = 0x5U

///|
const RleStartEnd : UInt = 0x6U

///|
const RleStartLength : UInt = 0x7U
