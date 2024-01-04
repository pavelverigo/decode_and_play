const std = @import("std");

const Wav = @This();

channel_cnt: u16,
sample_rate: u32,
pcm_data: []const u8,

pub fn decode(file_data: []const u8) Wav {
    var out: Wav = undefined;
    var cursor: usize = 0;
    while (cursor < file_data.len) {
        const chunk_identifier = file_data[cursor..][0..4];
        const chunk_length = std.mem.readInt(u32, file_data[cursor..][4..8], .little);

        const riff_or_list = std.mem.eql(u8, chunk_identifier, "RIFF") or std.mem.eql(u8, chunk_identifier, "LIST");
        if (riff_or_list) {
            const sub_chunk_identifier = file_data[cursor..][8..12];
            std.debug.print("chunk {s}, subchunk {s}, {}\n", .{ chunk_identifier, sub_chunk_identifier, chunk_length });
            cursor += 12;
        } else {
            std.debug.print("simple chunk {s}, {}\n", .{ chunk_identifier, chunk_length });

            if (chunk_length < 100) {
                std.debug.print("simple chunk is small, data: {x}\n", .{file_data[cursor..][8..][0..chunk_length]});
            }

            if (std.mem.eql(u8, chunk_identifier, "fmt ")) {
                out.channel_cnt = std.mem.readInt(u16, file_data[cursor..][8..][2..4], .little);
                out.sample_rate = std.mem.readInt(u32, file_data[cursor..][8..][4..8], .little);
            }

            if (std.mem.eql(u8, chunk_identifier, "data")) {
                out.pcm_data = file_data[cursor..][8..][0..chunk_length];
            }

            cursor += 8 + chunk_length + @mod(chunk_length, 2);
        }
    }
    return out;
}
