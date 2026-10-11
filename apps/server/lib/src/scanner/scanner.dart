/// ROM scanner engine: walks EmulationStation-style system folders of a
/// library root, groups files into game units, and hashes them.
///
/// Pure engine: no database, no HTTP. See [Scanner].
library;

export 'grouping.dart'
    show DiscoveredDirectory, DiscoveredFile, GameUnit, groupGameUnits;
export 'hashing.dart'
    show
        Crc32,
        FileHashes,
        HashFailure,
        HashPool,
        HashPoolClosed,
        defaultPartialHashChunk,
        defaultPartialHashThreshold,
        hashFileSync;
export 'rom_scanner.dart'
    show ScanJob, Scanner, ScannerOptions, skippedFolderNames;
export 'scan_models.dart';
export 'sheet_parser.dart' show parseCue, parseGdi, parseM3u, parseSheet;
export 'title_parser.dart'
    show ParsedTitle, discGroupKey, parseTitle, stripExtension;
