extends Node

@onready var music_handler: Node = $MusicHandler
@onready var sound_handler: Node = $SoundHandler


func play_music(music: AudioStream, single = false) -> void:
    music_handler.play(music, single)


func play_sound(sound: AudioStream) -> void:
    sound_handler.play(sound)


func stop_music() -> void:
    music_handler.stop()


func stop_sound() -> void:
    sound_handler.stop()
