# Remote Config Uitility Class
RemoteConfig is a wrapper class that works with the plugin, [firebase_remote_config](https://pub.dev/packages/firebase_remote_config), which in turn, uses the [Firebase Remote Config API](https://firebase.google.com/products/remote-config/) to communicate with the Remote Config cloud service offered to all Firebase projects.

**Installing**
I don't always like the version number suggested in the '[Installing](https://pub.dev/packages/mvc_application#-installing-tab-)' page.
Instead, always go up to the '**major**' semantic version number when installing my library packages. This means always entering a version number trailing with two zero, '**.0.0**'. This allows you to take in any '**minor**' versions introducing new features as well as any '**patch**' versions that involves bugfixes. Semantic version numbers are always in this format: **major.minor.patch**. 

1. **patch** - I've made bugfixes
2. **minor** - I've introduced new features
3. **major** - I've essentially made a new app. It's broken backwards-compatibility and has a completely new user experience. You won't get this version until you increment the **major** number in the pubspec.yaml file.

And so, in this case, add this to your package's pubspec.yaml file instead:
```javascript
dependencies:
   remote_config: ^1.0.0
```
For more information on version numbers: [The importance of semantic versioning](https://medium.com/@xabaras/the-importance-of-semantic-versioning-9b78e8e59bba).

## Firebase Console
When you go to your [Firebase console](https://console.firebase.google.com/?pli=1) in your own Firebase project, there's an option on the left-hand side called, *Remote Config*. Traditionally, Remote Config is used to store server-side default values to control the behavior and appearance of your app. This library package makes doing so that much easier for a Flutter developer.

![RemotConfig](https://user-images.githubusercontent.com/32497443/83059880-36fa6a80-a020-11ea-8b50-4a3dd78b1d4b.png)
## A Walkthrough
Let's walk through the RemoteConfig class found in the library file, **remote_config.dart**, and explain what it does. There's a screenshot below displaying the start of this class. Again, it works with the plugin that knows how to talk to Firebase's Remote Config, and you can see it being imported with the prefix, "r", in the screenshot below. Note, however, it also exports specific classes from the plugin file as well. This is so when using the library routine, you don't have to import the plugin file as well, you just import this one file.

Therefore, you can then only use one import statement:
```
import remote_config.dart
```
Instead of using two import statements:
```
import package:firebase_remote_config/firebase_remote_config.dart
import remote_config.dart
```
A further note in the constructor, I explicitly test the parameters if they're assigned **null**. With such a utility class used by the general populace, **null** values could be passed in - by accident or otherwise. In addition, the named parameters, defaults, and expiration used by the enclosed plugin are assured to be assigned valid values. Lastly, the class doesn't store the parameter values in instance variables. These values are instead passed to 'private' variables. They don't need to be accessible again as a public class property. It's a security precaution. Another characteristic of such a utility class.
![Constructor](https://user-images.githubusercontent.com/32497443/83061464-a3766900-a022-11ea-9d16-4b5a90c360db.png)
The next stretch of code lists the private variables and the getters used in this routine. The one of note, is the getter, _instance_, as it's a reference to the underlying Remote Config plugin itself. You likely won't need to reference it directly, but it's an option. 
![variables](https://user-images.githubusercontent.com/32497443/83062397-277d2080-a024-11ea-9242-594dbdb51e85.png)
## Init Your Remote
The next stretch of code is the **init**() function. I decided to have a separate **init**() function in this routine so to remind any developer using this class to not only call the **init**() function to initialize things but to also call its corresponding **dispose**() function to then 'clean things up.' In the screenshot of the **init**() function below you can see it's there where the Remote Config plugin is actually initialized. Further, any default values passed to the routine are then assigned to the plugin. Finally, it is there where the plugin's **fetch**() function is called to 'fetch' the parameter values stored in the Remote Config.
You'll notice an encryption key is conceived in the **init**() function as well. Encryption and Decryption your remote values is an option available to you when using this class. If this key was not explicitly passed to this function, the package name of your app is used to look up a possible key in Remote Config.
![Init](https://user-images.githubusercontent.com/32497443/83065877-d4a66780-a029-11ea-9f81-c22b1fabc75a.png)
Further note, the whole operation in the **init**() function is enclosed in a try-catch statement and any exceptions recorded. Any such utility class should record any and all exceptions. Lastly, a boolean value of true is returned if everything goes successfully.
The next stretch of code will mirror the properties and functions found in the plugin itself. Again, being a utility class - made available for public use, you have to ensure the routine is used properly. In this case, the **init**() function has to be called before you can do anything else, and that's what the series of **assert**() functions you see below are for. If the developer forgets to call the **init**() function, they'll know it if they try to work with the routine any further.
![mirrorPlugin](https://user-images.githubusercontent.com/32497443/83066083-20591100-a02a-11ea-8f2d-857da87cadcd.png)
What follows in the next bit of code is what you'll be using most often. You'll supply the appropriate key-value and retrieve parameter values from Firebase's Remote Config using the following functions. The **getStringed**() function is found here. Note, its role is to involve decryption in your value retreval. More on that later.
![setDefaults](https://user-images.githubusercontent.com/32497443/83066228-55fdfa00-a02a-11ea-8635-37f0d0415dc8.png)
The rest of the code below continues to mirror the functions available to the plugin itself. You can even add 'listeners' to introduce functions that will fire whenever a Remote Config value possibly changes during the app's execution.
![setBool](https://user-images.githubusercontent.com/32497443/83066352-8ba2e300-a02a-11ea-913f-ddbd9e938dfc.png)
## Remote Error
Lastly, in this RemoteConfig wrapper class, there's the code for recording any exceptions. If something goes wrong, there are two getters that you can use in your app itself to test if the wrapper class failed in any way. For instance, if either *_remoteConfig.hasError* or *_remoteConfig.inError* is set to true, there was an exception.
As you know by now, throughout the class and accompanying ever **try-catch** statement, the function, **getError**(), is called to record any exceptions. Well, your app can also call **getError**() without a parameter to retrieve the actual exception that has occurred and act accordingly. That means, as a developer, you can use the function as well in your own Flutter app to test if your remote config operations were successful or not.
![getError](https://user-images.githubusercontent.com/32497443/83066510-c73dad00-a02a-11ea-8870-2314bd3a3e85.png)
## Decrypt The Encrypted
With this Remote Config routine, I had a need for the use of Cryptography. As it happens, that's what the getStringed() function is for-to decrypt the Remote Config values. Of course, using your favourite IDE and breakpoints, you'll have to first encrypt those values and store them up there in your own Remote Config the first place. And so, there is a StringCrypt class for you to do this, and it's listed below. It works with another popular plugin called, *flutter_string_encryption.dart*, using the class, **PlatformStringCryptor**().
Again, like the Remote Config routine, this class doesn't store it's three parameters in class properties but instead takes them into private variables. You can also see its plugin is initialized in the constructor. Lastly, instead of explicitly providing the plugin a key parameter, you can instead provide a password and 'salt' to generate the key. Such keys are required to generate encryption.
The 'salt' parameter is an additional string that accompanies the password when generating a key for encryption and decryption. It's an additional safeguard in case the password is ever compromised. It's 'one more component' needed if a bad guy wants its access.
![StringCrypt](https://user-images.githubusercontent.com/32497443/83066917-65317780-a02b-11ea-90a6-2432fe9abac9.png)
Below, you now see the 'decrypt' routines used by the RemoteConfig class. In addition, you see the functions you would use to first generate a key you'd then store away on Remote Config for example.
![Decrypt](https://user-images.githubusercontent.com/32497443/83067043-99a53380-a02b-11ea-8e3f-3721daaabfc9.png)
The private function, **_keyFromPassword**(), is pretty self-explanatory. If there's a password and a salt provided, it's called back up in the constructor and assigns a key to the private variable, _key.

Lastly, you'll recognize the bit of code at the very end of this class. Again, such a utility class should catch any and all exceptions and save it for the developer to optionally retrieve and act upon accordingly. That code is listed below.
![keyFromPassword](https://user-images.githubusercontent.com/32497443/83067207-db35de80-a02b-11ea-92fc-cbefa486297a.png)
# An Example
The routine below is a screenshot of one of my ongoing projects. It calls the plugin, *flutter_twitter*, but not before accessing the project's Remote Config and supplying the two required String values. You can see this routine draws out the app's package name and uses the first two parts, 'com' and 'andrioussolutions', to retrieve the particular Remote Config values you first saw in the Firebase Console screenshot above.
![RemoteConfig Example](https://user-images.githubusercontent.com/32497443/83060527-357d7200-a021-11ea-83cd-205f4c2ff013.png)
The function, **getStringed**(), will be of particular interest. It returns the String values from the Remote Config, but no before decrypting the retrieved value. The function is called for both the public key and the secret token as you can see highlighted in the screenshot below. Hence, back in the screenshot of the Remote Config screen for that particular Firebase project above, the values stored there are, in fact, the encrypted versions of the public key and secret token.

Taking a peek at the class library, *RemoteConfig*, we can see the function calls its regular **getString**() function used to retrieve the String value from Firebase's Remote Config, but then it passes that value to an asynchronous function called, **de**().
![getStringed](https://user-images.githubusercontent.com/32497443/83060782-9e64ea00-a021-11ea-961c-c5d7258801af.png)
It's an abbreviation form of the function, **decrypt**(), which in turn, calls this other function to perform the actual decryption. A screenshot of these functions is displayed below. Of course, it's not recommended you store such sensitive information in Google's cloud service.
![Decrypt](https://user-images.githubusercontent.com/32497443/83060982-e08e2b80-a021-11ea-879d-d44e55e38bb0.png)

This utility class, *RemoteConfig*, was written up out of necessity - I needed to work with Firebase's Remote Config service. I've supplied this class and the StringCrypt class to our fledgling Flutter community.

Cheers.