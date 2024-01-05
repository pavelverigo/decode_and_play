const std = @import("std");
const mem = std.mem;

const Wav = @This();

// https://www.lim.di.unimi.it/IEEE/VROS/RIFF.HTM

// assume WAVE_FORMAT_PCM
const Format = struct {
    channel_cnt: u16,
    sample_rate: u32,
    avg_bytes_per_sec: u32,
    block_align: u16,
    bits_per_sample: u16,
};

format: Format,
pcm_data: []const u8,

fn fullChunkLen(chunk_len: u32) u32 {
    return 8 + chunk_len + @mod(chunk_len, 2);
}

// skim through RIFF file
// NOTE:
// - not verifying uniqueness of "RIFF"/"fmt "/"data" chunks
// - not verifying chunks after "data" chunk
pub fn decode(file_data: []const u8) !Wav {
    var out: Wav = undefined;
    var cursor: usize = 0;

    // first chunk is RIFF(WAVE)
    {
        if (file_data.len < 8) return error.DecodeFail;
        if (!mem.eql(u8, file_data[cursor..][0..4], "RIFF")) return error.DecodeFail;
        const riff_len = mem.readInt(u32, file_data[cursor..][4..8], .little);
        if (file_data.len != fullChunkLen(riff_len)) return error.DecodeFail;
        if (!mem.eql(u8, file_data[cursor..][8..12], "WAVE")) return error.DecodeFail;

        cursor += 12;
    }

    // find fmt chunk
    while (true) {
        if (file_data.len < cursor + 8) return error.DecodeFail;
        const chunk_id = file_data[cursor..][0..4];
        const chunk_len = mem.readInt(u32, file_data[cursor..][4..8], .little);
        if (file_data.len < cursor + fullChunkLen(chunk_len)) return error.DecodeFail;
        const chunk_data = file_data[cursor..][8..][0..chunk_len];
        cursor += fullChunkLen(chunk_len);

        if (mem.eql(u8, chunk_id, "fmt ")) {
            if (chunk_data.len < 16) return error.DecodeFail; // assumes WAVE_FORMAT_PCM

            if (mem.readInt(u16, chunk_data[0..2], .little) != 0x0001) return error.DecodeFail; // support only WAVE_FORMAT_PCM
            out.format.channel_cnt = mem.readInt(u16, chunk_data[2..4], .little);
            out.format.sample_rate = mem.readInt(u32, chunk_data[4..8], .little);
            out.format.avg_bytes_per_sec = mem.readInt(u32, chunk_data[8..12], .little);
            out.format.block_align = mem.readInt(u16, chunk_data[12..14], .little);
            out.format.bits_per_sample = mem.readInt(u16, chunk_data[14..16], .little);

            break;
        }

        if (cursor == file_data.len) return error.DecodeFail;
    }

    // find data chank
    while (true) {
        if (file_data.len < cursor + 8) return error.DecodeFail;
        const chunk_id = file_data[cursor..][0..4];
        const chunk_len = mem.readInt(u32, file_data[cursor..][4..8], .little);
        if (file_data.len < cursor + fullChunkLen(chunk_len)) return error.DecodeFail;
        const chunk_data = file_data[cursor..][8..][0..chunk_len];
        cursor += fullChunkLen(chunk_len);

        if (mem.eql(u8, chunk_id, "data")) {
            out.pcm_data = chunk_data;
            break;
        }

        if (cursor == file_data.len) return error.DecodeFail;
    }

    return out;
}
