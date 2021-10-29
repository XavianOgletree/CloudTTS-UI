# Summary

A basic utility for interfacing with Google Cloud or IBM TTS. This was developed to help streamline my work while creating [my thesis project](https://etd.ohiolink.edu/apexprod/rws_olink/r/1501/10?clear=10&p10_accession_num=wright1621853024907269).

![Screen shot of the TTS interface](screen-shots/screenshot.png)

# Development
## Requirements
In order to develop and build this project from source, you'll need to complete the following steps:

1. Download the latest version of Godot 3.X from [here](https://downloads.tuxfamily.org/godotengine/).
2. Import the project into Godot using the project viewer.
3. Finally, [install the build templates from the editor.](https://docs.godotengine.org/en/stable/getting_started/workflow/export/exporting_projects.html)

With these steps completed, you should now be ready to develop and export the application. If you unfamiliar with Godot and GDScript, please refer to the [documentation](https://docs.godotengine.org/en/stable/about/introduction.html).

## Adding A New API

In order to add a new API, implement the `TextToSpeechApi.gd` interface. Then add an instance of your API to the `api_list` in `Editor.gd`. For details about how an API should be implement, view the comments in `TextToSpeechApi.gd` and refer to the implementation of `GoogleTextToSpeechApi.gd` and `IBMTextToSpeechApi.gd`.

# License

This code base uses the MIT license. Including my name in your project and linking to my license is sufficient for satisfying the license's terms.