# GeocodesKit

GeocodesKit is a library for managing geolocation codes as a Realm database. The example
application included with the library can be run on a Mac OS desktop to read various
code files and generate a compacted Realm database that can be bundled into an iOS app.

## Generate a database file

1. Download ICD-10-CM source files ("Code Tables, Tabular, and Index") from CMS:

  https://www.cms.gov/medicare/coding-billing/icd-10-codes

  https://www.cms.gov/files/zip/2025-code-tables-tabular-and-index-april.zip

2. To run the example project, clone the repo, and run `pod install` from the Example directory first.

3. Then, open the `Example/GeocodesKit.xcworkspace` in Xcode. Change the build target to `My Mac` and run.

4. Click on `Import` in the toolbar. Find the `icd10cm-tabular-2024.xml` in the file browser and click on Open.

5. Wait as the file is parsed and imported into a Realm database, until the spinner disappears and the Export
option is enabled in the toolbar.

6. Click on Export, and select a destination for the Realm database file.

## Installation

1. Include GeocodesKit in your iOS app project using Swift Package Manger, referencing this repository:

    https://github.com/peakresponse/peak-ios-geocodeskit

2. Add the exported Realm database file generated previously to your iOS app project.

3. Initialize the library with the Realm file, for example in your AppDelegate didFinishLaunchingWithOptions function.

  ```
  import GeocodesKit
  ...
  class AppDelegate: UIResponder, UIApplicationDelegate {
      ...
      func application(_ application: UIApplication,
                       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
          ...
          CMRealm.configure(url: Bundle.main.url(forResource: "ICD10CM", withExtension: "realm"), isReadOnly: true)
      }
      ...
  }
  ```

4. Use as with any Realm database model. For example, in a table view controller (see https://docs.mongodb.com/realm/sdk/swift/examples/react-to-changes/#register-a-collection-change-listener):

  ```
  class CodesViewController: UITableViewController {    
      var results: Results<CMCode>?
      ...
      func viewDidLoad() {
        ...
        results = CMRealm.open().objects(CMCode.self).sorted(byKeyPath: "name", ascending: true)
      }
      ...      
  }
  ```

## Author

Francis Li, francis@peakresponse.net

## License

GeocodesKit  
Copyright &copy; 2025 Peak Response Inc.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
