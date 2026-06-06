/// Info.plist keys Koban reads at runtime. Apple documents these as string keys, so naming them
/// here keeps the bare strings out of logic (see CLAUDE.md: no magic values).
enum BundleKeys {
    /// The marketing version (e.g. "1.2.0"), shown on the home dashboard.
    static let shortVersionString = "CFBundleShortVersionString"
}
