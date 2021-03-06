#include <vclmin.h>
#pragma hdrstop

/*---------------------------------------------------------------------------
 *  Note about used '#defines'.
 *  Global defined in the makefile.
 *		WIN32						Windows '95 and NT.
 *		NDEBUG					Don't use included debug code. (See also DEBUG and Trace!)
 *		REENTRANT				Use Reentrant code. Do not use with: DYNALLOC_CRCTAB
 *  Defined elswhere.
 *		MSDOS						Used for the file system.
 *		ZCR_SEED2				Zip Crypt Random Seed no. 2.
 *									(Used to set a part of the random seed generator.)
 *  Not defined at the moment but possible to set.
 *		NOCPYRT					Do not include the static copyright lines.
 *									To set differently look in Version.h
 *		ASM_CRC					Use Assembler source to calculate the CRC.
 *									(Not included yet, maybe in BCB 4).
 *		DEBUG						Use debug code. (see also NDEBUG and Trace!)
 *		Trace						Use special trace mode. (See also DEBUG and NDEBUG!)
 *		DUMP_BL_TREE			Extra debugging aid; Dumps a tree via stderr. (in Trees.c)
 *		CRYPT_DEBUG				Use debug code in crypt module.
 *		DYN_ALLOC				Use dynamic allocated memory in Deflate.c and Trees.c
 *		DYNAMIC_CRC_TABLE		Used if the CRC table must be calcualted (now is static.)
 *		DYNALLOC_CRCTAB		Used if CRC table must be allocated dynamicly.
 *									only in combination with: DYNAMIC_CRC_TABLE.
 *		USE_EF_UX_TIME			???
 *		S_IFLNK					Use symbolic links. (in fileio.c)
 *		NO_SYMLINK				Do not use symbolic links even if S_IFLNK is defined.
 *		USE_MEMCHECK			Check for memory leaks within the dll.
 *
 *		FORCE_METHOD			??? in Trees.c ( forced storing of data )
 *		NO_UNROLLED_LOOPS		??? in crc32.c
 *		REALLY_SHORT_SYMS		??? in crypt.h
 *		FULL_SEARCH				??? in deflate.c
 *		HUFFMAN_ONLY			??? in deflate.c
 *		FILTERED					??? in deflate.c
 *		FORCE_NEWNAME			??? in FileIO.c
 *
 *  Note about the editor.
 *		To show the source orderly set the tabstops as following:
 *		4 7 10 13 16 19 22 25 28 31 34 37 40 43 46 ...
 *---------------------------------------------------------------------------
 * Changes in version 1.53
 *
 * -Made the Dll reentrant, all non constant globals are now placed in one single
 *  structure per thread.
 *  (This should also solve a bug showing when calling the dll multiple times
 *  without unloading the dll first.)
 *
 * Changes in version 1.54
 *
 * -Solved a bug in ZipFile.c caused by replacing forward slashes in backward slashes
 *  [ In previous versions the dll code looked at both forward and backward slashes and
 *   treated them the same. Now all internal code uses and looks for the backward slash.
 *   But since ZipFiles should only have forward slashes conversion is needed:
 *   This means that when reading a zipfile the forward slash is replaced by a backward one
 *   and when writing vice versa. Also FileSpec and FileSpecExcl are scanned for forward
 *   slashes and replaced when needed.]
 *
 * Changes in version 1.55
 *
 * -AddSetTime did not work because the file was not opened in write mode.
 * -When using AddForceDOS filenames were not displayed properly although the zipping did work.
 *
 * Changes in version 1.60
 *
 * -1.601 Added the possibility to add a zipcomment created in the component
 *  for this it was neccessary to remove the reading of this comment from the dll.
 *  (replaced by a temporary variable.)
 * -1.602 Changed the behaviour with UPDATE if the file was empty and Append was true which
 *  is always the case for now. (150199)
 *  There was a message 'xxx does not exists or is empty' and the zipping stopped.
 * -1.603 Added the directive USE_MEMCHECK for testing on memory leaks.
 * -1.604 Fixed a memory leak when using encrypted without giving a password first.
 *  also fixed the function call to getp. (pG added at the end)
 * -1.605 Added support for a list of file specs to exclude.
 *  Fixed a memory leak in newname in FileIO.c while using the new exclude file spec.
 * -1.606 Removed some unnecessary function parameters found by BCB4.
 *
 */
USERES(  "ZipDlg.res" );
USEUNIT( "Bits.c" );
USEUNIT( "Crc32.c" );
USEUNIT( "Crctab.c" );
USEUNIT( "Crypt.c" );
USEFILE( "Crypt.h" );
USEUNIT( "Deflate.c" );
USEUNIT( "Dllmain.c" );
USEUNIT( "Dllzip.c" );
USEUNIT( "Fileio.c" );
USEUNIT( "Globals.c" );
USEUNIT( "Passmsg.c" );
USEUNIT( "Trees.c" );
USEUNIT( "ZipUp.c" );
USEFILE( "ZipUp.h" );
USEUNIT( "Win32.c" );
USEUNIT( "Win32zip.c" );
USEFILE( "Win32zip.h" );
USEUNIT( "Zipfile.c" );
USEUNIT( "Util.c" );
USEFILE( "Osdep.h" );
USEFILE( "Resource.h" );
USEFILE( "Tailor.h" );
USEFILE( "Ttyio.h" );
USEFILE( "Version.h" );
USEFILE( "Wizzip.h" );
USEFILE( "Zip.h" );
USEFILE( "Ziperr.h" );

// Every process will (normally) have it's own version.
DWORD TgbIndex;	// The only global used by all threads except for some constants.

extern "C" void ReleaseGlobalPointer( void );

//---------------------------------------------------------------------------
int WINAPI DllEntryPoint( HINSTANCE hinst, unsigned long reason, void * ) {
	switch ( reason ) {
		case DLL_PROCESS_ATTACH:	// Allocate a index.
			if ( (TgbIndex = TlsAlloc()) == 0xFFFFFFFF ) return 0;
			break;

		case DLL_PROCESS_DETACH:
			ReleaseGlobalPointer();
			TlsFree( TgbIndex );		// Release the index.
	}
	return 1;
}

