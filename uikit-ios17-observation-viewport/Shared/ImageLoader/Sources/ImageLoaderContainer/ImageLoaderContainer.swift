import ImageLoader
import PersistenceInterface

public enum ImageLoaderContainer {
    public static func bootstrap(
        dataLoader: ImageDataLoader,
        diskClient: FileClient,
        diskCacheConfiguration: ImageDiskCacheConfiguration = .default
    ) {
        ImageLoader.bootstrap(
            engine: .firstParty(dataLoader: dataLoader),
            diskClient: diskClient,
            diskConfiguration: diskCacheConfiguration
        )
    }
}
