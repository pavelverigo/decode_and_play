const std = @import("std");
const Wav = @import("Wav.zig");

extern fn win_xaudio2_init() i32;
extern fn win_xaudio2_play_pcm(u16, u32, u32, u16, u16, [*]const u8, u32) i32;
extern fn win_xaudio2_deinit() i32;

const wav_file_data = @embedFile("Rift Riders.wav");

pub fn main() !void {
    const wav = try Wav.decode(wav_file_data);

    std.debug.print("{}", .{wav.format});

    if (win_xaudio2_init() < 0) unreachable;
    if (win_xaudio2_play_pcm(
        wav.format.channel_cnt,
        wav.format.sample_rate,
        wav.format.avg_bytes_per_sec,
        wav.format.block_align,
        wav.format.bits_per_sample,
        wav.pcm_data.ptr,
        @intCast(wav.pcm_data.len),
    ) < 0) unreachable;
    if (win_xaudio2_deinit() < 0) unreachable;
}
