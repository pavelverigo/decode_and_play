const std = @import("std");
const Wav = @import("Wav.zig");

extern fn win_xaudio2_init() i32;
extern fn win_xaudio2_play_pcm(u16, u32, [*]const u8, u32) i32;
extern fn win_xaudio2_deinit() i32;

const wav_file_data = @embedFile("Rift Riders.wav");

pub fn main() !void {
    const wav = Wav.decode(wav_file_data);

    if (win_xaudio2_init() < 0) unreachable;
    if (win_xaudio2_play_pcm(wav.channel_cnt, wav.sample_rate, wav.pcm_data.ptr, @intCast(wav.pcm_data.len)) < 0) unreachable;
    if (win_xaudio2_deinit() < 0) unreachable;
}
