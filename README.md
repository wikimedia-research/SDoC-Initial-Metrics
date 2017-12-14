# Baseline Metrics for SDoC

As the [Structured Data on Commons](https://commons.wikimedia.org/wiki/Commons:Structured_data) (SDoC) project ramps up, we'll need to figure out a baseline for metrics on [Wikimedia Commons](https://meta.wikimedia.org/wiki/Wikimedia_Commons) in order to measure future successes. This work is tracked in Phabricator ticket [T174519](https://phabricator.wikimedia.org/T174519).

**Note**: [Manual:Database layout](https://www.mediawiki.org/wiki/Manual:Database_layout) will be very useful in this endeavor.

- [x] [T177356](https://phabricator.wikimedia.org/T177356): file-based metrics
    - [x] How many: mpeg's, png's, ogg's, etc.
    - [x] Track organic growth rate of uploads (historical trends); don’t include files uploaded and then deleted before a certain threshold or uploaded by an account that was deleted (e.g. spam bots)
        - [x] By file type -- including 3D (STL), vector formats, etc.
    - [x] How many files are getting deleted?
        - [x] How many are deleted for copyright violations
        - [x] Average time to deletion
        - [x] How many people are involved in flagging for deletion/deleting files
- [x] [T177354](https://phabricator.wikimedia.org/T177354): bots vs users
    - [x] How many files are uploaded by bots vs users
        - [x] Breakdown by media type
        - [x] Historical trends
- [x] [T177534](https://phabricator.wikimedia.org/T177534): Search Metrics for SDoC: eventlogging
- [x] [T177358](https://phabricator.wikimedia.org/T177358): Metrics for SDoC: translations
    - [x] how many files/descriptions are in multiple languages?
        - [x] How many files are in lang X?
        - [x] How many have multiple languages in them?
        - [x] How many Western industrialized languages?
    - [x] How many search queries happen in what languages?
- [x] [T177353](https://phabricator.wikimedia.org/T177353): "Unfindable" images metrics
    - [x] Lack of categorization
    - [x] Lack of description
    - [x] [ImageNote](https://commons.wikimedia.org/wiki/Template:ImageNote)

## Further Reading

- [MrMetadata](https://tools.wmflabs.org/mrmetadata/)
    - File metadata cleanup drive from September 2014
    - See [*Cleaning up file metadata, for humans and robots*](https://blog.wikimedia.org/2014/11/07/cleaning-up-file-metadata-for-humans-and-robots/) blog post by Guillaume Paumier
