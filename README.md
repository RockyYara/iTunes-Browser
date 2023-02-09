# iTunes-Browser

### This is a test project I wrote during application to one of IT companies in May 2019.

The project contains 2 parts: **ITunesBrowsing**, which is a framework, and **iTunes Browser**, which is the app that uses the framework.

$~$

**The task was to implement the following iOS app:**

- the app should asynchronously get list of objects from iTunes (arbitrary kinds of objects: music, books, software) in JSON and display it in UITableView;
- there should be capability to change search criteria, and after its change the list should be reloaded;
- the last search string should be saved;
- images should load asynchronously;
- there should be capability to select objects in the list using swipe;
- selected objects should be stored locally using CoreData;
- locally stored objects should be displayed in separate ViewController in UITableView;
- objects, which were stored locally earlier, should be marked in the list loaded from iTunes;
- there should be capability to delete locally stored objects, this action should be completed after confirmation request and playing sound;
- for local storage object image should be converted to grayscale (no storage in Photo Gallery, CoreData should be used);
- at least one ViewController should be in separate framework and should be loaded from there;
- framework should be built for all architectures (both for simulator and for real devices);
- AutoLayout should be used, UI elements should be arranged the way to demonstrate understanding of how AutoLayout works;
- the app should support both portrait & landscape modes, both iPhone & iPad;
- the app should be implemented using Swift, but at least one Objective C source file should be present (it can contain arbitrary code, but this code should be run);
- all things that are not described here remain for the developer's will.
