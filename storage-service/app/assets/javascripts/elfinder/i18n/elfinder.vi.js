/**
 * Vietnam translation
 * @author Régis Guyomarch <regisg@gmail.com>
 * @version 2011-07-11
 */
if (elFinder && elFinder.prototype && typeof(elFinder.prototype.i18) == 'object') {
	elFinder.prototype.i18.vi = {
		translator : 'doankien.bui@gmail.com&gt;',
		language   : 'vietnam',
		direction  : 'ltr',
		messages   : {

			/********************************** errors **********************************/
			'error'                : 'Cảnh báo',
			'errUnknown'           : 'Unknown error.',
			'errUnknownCmd'        : 'Unknown command.',
			'errJqui'              : 'Invalid jQuery UI configuration. Selectable, draggable and droppable components must be included.',
			'errNode'              : 'elFinder requires DOM Element to be created.',
			'errURL'               : 'Invalid elFinder configuration! URL option is not set.',
			'errAccess'            : 'Access denied.',
			'errConnect'           : 'Unable to connect to backend.',
			'errAbort'             : 'Connection aborted.',
			'errTimeout'           : 'Connection timeout.',
			'errNotFound'          : 'Backend not found.',
			'errResponse'          : 'Chức năng này đang được hoàn thiện',
			'errConf'              : 'Invalid backend configuration.',
			'errJSON'              : 'PHP JSON module not installed.',
			'errNoVolumes'         : 'Readable volumes not available.',
			'errCmdParams'         : 'Invalid parameters for command "$1".',
			'errDataNotJSON'       : 'Data is not JSON.',
			'errDataEmpty'         : 'Data is empty.',
			'errCmdReq'            : 'Backend request requires command name.',
			'errOpen'              : 'Unable to open "$1".',
			'errNotFolder'         : 'Object is not a folder.',
			'errNotFile'           : 'Object is not a file.',
			'errRead'              : 'Unable to read "$1".',
			'errWrite'             : 'Unable to write into "$1".',
			'errPerm'              : 'Không có quyền.',
			'errLocked'            : '"$1" is locked and can not be renamed, moved or removed.',
			'errExists'            : 'File named "$1" already exists.',
			'errInvName'           : 'Invalid file name.',
			'errFolderNotFound'    : 'Folder not found.',
			'errFileNotFound'      : 'File not found.',
			'errTrgFolderNotFound' : 'Target folder "$1" not found.',
			'errPopup'             : 'Browser prevented opening popup window. To open file enable it in browser options.',
			'errMkdir'             : 'Unable to create folder "$1".',
			'errMkfile'            : 'Unable to create file "$1".',
			'errRename'            : 'Unable to rename "$1".',
			'errCopyFrom'          : 'Copying files from volume "$1" not allowed.',
			'errCopyTo'            : 'Copying files to volume "$1" not allowed.',
			'errUploadCommon'      : 'Upload error.',
			'errUpload'            : 'Unable to upload "$1".',
			'errUploadNoFiles'     : 'No files found for upload.',
			'errMaxSize'           : 'Data exceeds the maximum allowed size.',
			'errFileMaxSize'       : 'File exceeds maximum allowed size.',
			'errUploadMime'        : 'File type not allowed.',
			'errUploadTransfer'    : '"$1" transfer error.',
			'errSave'              : 'Unable to save "$1".',
			'errCopy'              : 'Unable to copy "$1".',
			'errMove'              : 'Unable to move "$1".',
			'errCopyInItself'      : 'Unable to copy "$1" into itself.',
			'errRm'                : 'Unable to remove "$1".',
			'errExtract'           : 'Unable to extract files from "$1".',
			'errArchive'           : 'Unable to create archive.',
			'errArcType'           : 'Unsupported archive type.',
			'errNoArchive'         : 'File is not archive or has unsupported archive type.',
			'errCmdNoSupport'      : 'Backend does not support this command.',
			'errReplByChild'       : '“$1” không thể thực hiện lệnh',
			'errArcSymlinks'       : 'For security reason denied to unpack archives contains symlinks.',
			'errArcMaxSize'        : 'Archive files exceeds maximum allowed size.',

			/******************************* commands names ********************************/
			'cmdarchive'   : 'Nén',
			'cmdback'      : 'Lùi',
			'cmdcopy'      : 'Sao chép',
			'cmdcut'       : 'Cắt',
			'cmddownload'  : 'Tải xuống',
			'cmdduplicate' : 'Nhân bản',
			'cmdedit'      : 'Sửa',
			'cmdextract'   : 'Giải nén',
			'cmdforward'   : 'Tiếp',
			'cmdgetfile'   : 'Xem',
			'cmdhelp'      : 'Help',
			'cmdhome'      : 'Thư mục gốc',
			'cmdinfo'      : 'Thông tin',
			'cmdmkdir'     : 'Tạo thư mục',
			'cmdmkfile'    : 'Tạo file',
			'cmdopen'      : 'Mở',
			'cmdpaste'     : 'Dán',
			'cmdquicklook' : 'Xem trước',
			'cmdreload'    : 'Làm mới',
			'cmdrename'    : 'Đổi tên',
			'cmdrm'        : 'Xoá',
			'cmdsearch'    : 'Tìm kiếm',
			'cmdup'        : 'Thoát',
			'cmdupload'    : 'Tải lên',
			'cmdview'      : 'Xem',
			'cmdresize'    : 'Chỉnh sửa',
			'cmdsort'      : 'Sắp xếp',

			/*********************************** buttons ***********************************/
			'btnClose'  : 'Đóng',
			'btnSave'   : 'Lưu',
			'btnRm'     : 'Xoá',
            'btnApply'  : 'Đồng ý',
			'btnCancel' : 'Huỷ',
			'btnNo'     : 'Không',
			'btnYes'    : 'Có',

			/******************************** notifications ********************************/
			'ntfopen'     : 'Đang mở thư mục',
			'ntffile'     : 'Đang mở file',
			'ntfreload'   : 'Đang tải lại',
			'ntfmkdir'    : 'Tạo thư mục',
			'ntfmkfile'   : 'Tạo file',
			'ntfrm'       : 'Xoá file',
			'ntfcopy'     : 'Sao chép file',
			'ntfmove'     : 'Di chuyển file',
			'ntfprepare'  : 'Chuẩn bị sao chép file',
			'ntfrename'   : 'Sửa tên file',
			'ntfupload'   : 'Đang thực hiện tải lên',
			'ntfdownload' : 'Đang thực hiện tải xuống',
			'ntfsave'     : 'Đang lưu',
			'ntfarchive'  : 'Tạo nén',
			'ntfextract'  : 'Đang giải nén',
			'ntfsearch'   : 'Đang tìm kiếm',
			'ntfsmth'     : 'Đang thực hiện',
            
			/************************************ dates **********************************/
			'dateUnknown' : 'Không rõ',
			'Today'       : 'Hôm nay',
			'Yesterday'   : 'Hôm qua',
			'Jan'         : 'Tháng 1',
			'Feb'         : 'Tháng 2',
			'Mar'         : 'Tháng 3',
			'Apr'         : 'Tháng 4',
			'May'         : 'Tháng 5',
			'Jun'         : 'Tháng 6',
			'Jul'         : 'Tháng 7',
			'Aug'         : 'Tháng 8',
			'Sep'         : 'Tháng 9',
			'Oct'         : 'Tháng 10',
			'Nov'         : 'Tháng 11',
			'Dec'         : 'Tháng 12',

			/******************************** sort variants ********************************/
			'sortnameDirsFirst' : 'by name (folders first)',
			'sortkindDirsFirst' : 'by kind (folders first)',
			'sortsizeDirsFirst' : 'by size (folders first)',
			'sortdateDirsFirst' : 'by date (folders first)',
			'sortname'          : 'by name',
			'sortkind'          : 'by kind',
			'sortsize'          : 'by size',
			'sortdate'          : 'by date',

			/********************************** messages **********************************/
			'confirmReq'      : 'Yêu cầu xác nhận',
			'confirmRm'       : 'Bạn có chắc muốn xoá không ? File đã xoá không thể được khôi phục',
			'confirmRepl'     : 'Thay thế file cũ bằng file mới ?',
			'apllyAll'        : 'Xác nhận hết',
			'name'            : 'Tên',
			'size'            : 'Kích thước',
			'perms'           : 'Quyền',
			'modify'          : 'Sửa',
			'kind'            : 'Loại',
			'read'            : 'Đọc',
			'write'           : 'Ghi',
			'noaccess'        : 'Không có quyền',
			'and'             : 'và',
			'unknown'         : 'không rõ',
			'selectall'       : 'Chọn hết',
			'selectfiles'     : 'Chọn file(s)',
			'selectffile'     : 'Chọn file đầu tiên',
			'selectlfile'     : 'Chọn file cuối cùng',
			'viewlist'        : 'Hiển thị theo danh sách',
			'viewicons'       : 'Hiển thị theo icon',
            'places'          : 'Places',
			'calc'            : 'Calculate',
			'path'            : 'Path',
			'aliasfor'        : 'Alias for',
			'locked'          : 'Khoá',
			'dim'             : 'Dimensions',
			'files'           : 'Files',
			'folders'         : 'Folders',
			'items'           : 'Items',
			'yes'             : 'có',
			'no'              : 'không',
			'link'            : 'Link',
			'searcresult'     : 'Search results',
			'selected'        : 'selected items',
			'about'           : 'About',
			'shortcuts'       : 'Shortcuts',
			'help'            : 'Help',
			'webfm'           : 'Web file manager',
			'ver'             : 'Version',
			'protocol'        : 'protocol version',
			'homepage'        : 'Project home',
			'docs'            : 'Documentation',
			'github'          : 'Fork us on Github',
			'twitter'         : 'Follow us on twitter',
			'facebook'        : 'Join us on facebook',
			'team'            : 'Team',
			'chiefdev'        : 'chief developer',
			'developer'       : 'developer',
			'contributor'     : 'contributor',
			'maintainer'      : 'maintainer',
			'translator'      : 'translator',
			'icons'           : 'Icons',
			'dontforget'      : 'and don\'t forget to take your towel',
			'shortcutsof'     : 'Shortcuts disabled',
			'dropFiles'       : 'Gắp file vào đây',
			'or'              : 'hoặc',
			'selectForUpload' : 'Chọn file để tải lên',
			'moveFiles'       : 'Di chuyển files',
			'copyFiles'       : 'Sao chép files',
			'rmFromPlaces'    : 'Remove from places',
			'errReplByChild'  : '“$1” không thể thực hiện lệnh',
			'untitled folder' : 'untitled folder',
			'untitled file.txt' : 'untitled file.txt',

			/********************************** mimetypes **********************************/
			'kindUnknown'     : 'Unknown',
			'kindFolder'      : 'Thư mục',
			'kindAlias'       : 'Alias',
			'kindAliasBroken' : 'Broken alias',
			// applications
            'kindApp'         : 'Application',
			'kindPostscript'  : 'Postscript document',
			'kindMsOffice'    : 'Microsoft Office document',
			'kindMsWord'      : 'Microsoft Word document',
			'kindMsExcel'     : 'Microsoft Excel document',
			'kindMsPP'        : 'Microsoft Powerpoint presentation',
			'kindOO'          : 'Open Office document',
			'kindAppFlash'    : 'Flash application',
			'kindPDF'         : 'Portable Document Format (PDF)',
			'kindTorrent'     : 'Bittorrent file',
			'kind7z'          : '7z archive',
			'kindTAR'         : 'TAR archive',
			'kindGZIP'        : 'GZIP archive',
			'kindBZIP'        : 'BZIP archive',
			'kindZIP'         : 'ZIP archive',
			'kindRAR'         : 'RAR archive',
			'kindJAR'         : 'Java JAR file',
			'kindTTF'         : 'True Type font',
			'kindOTF'         : 'Open Type font',
			'kindRPM'         : 'RPM package',
			// texts
            'kindText'        : 'Text document',
			'kindTextPlain'   : 'Plain text',
			'kindPHP'         : 'PHP source',
			'kindCSS'         : 'Cascading style sheet',
			'kindHTML'        : 'HTML document',
			'kindJS'          : 'Javascript source',
			'kindRTF'         : 'Rich Text Format',
			'kindC'           : 'C source',
			'kindCHeader'     : 'C header source',
			'kindCPP'         : 'C++ source',
			'kindCPPHeader'   : 'C++ header source',
			'kindShell'       : 'Unix shell script',
			'kindPython'      : 'Python source',
			'kindJava'        : 'Java source',
			'kindRuby'        : 'Ruby source',
			'kindPerl'        : 'Perl script',
			'kindSQL'         : 'SQL source',
			'kindXML'         : 'XML document',
			'kindAWK'         : 'AWK source',
			'kindCSV'         : 'Comma separated values',
			'kindDOCBOOK'     : 'Docbook XML document',
			// images
			'kindImage'       : 'Image',
			'kindBMP'         : 'BMP image',
			'kindJPEG'        : 'JPEG image',
			'kindGIF'         : 'GIF Image',
			'kindPNG'         : 'PNG Image',
			'kindTIFF'        : 'TIFF image',
			'kindTGA'         : 'TGA image',
			'kindPSD'         : 'Adobe Photoshop image',
			'kindXBITMAP'     : 'X bitmap image',
			'kindPXM'         : 'Pixelmator image',
			// media
			'kindAudio'       : 'Audio media',
			'kindAudioMPEG'   : 'MPEG audio',
			'kindAudioMPEG4'  : 'MPEG-4 audio',
			'kindAudioMIDI'   : 'MIDI audio',
			'kindAudioOGG'    : 'Ogg Vorbis audio',
			'kindAudioWAV'    : 'WAV audio',
			'AudioPlaylist'   : 'MP3 playlist',
			'kindVideo'       : 'Video media',
			'kindVideoDV'     : 'DV movie',
			'kindVideoMPEG'   : 'MPEG movie',
			'kindVideoMPEG4'  : 'MPEG-4 movie',
			'kindVideoAVI'    : 'AVI movie',
			'kindVideoMOV'    : 'Quick Time movie',
			'kindVideoWM'     : 'Windows Media movie',
			'kindVideoFlash'  : 'Flash movie',
			'kindVideoMKV'    : 'Matroska movie',
			'kindVideoOGG'    : 'Ogg movie'
		}
	}
}