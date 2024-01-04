#define WIN32_LEAN_AND_MEAN 1
#include <windows.h>
#include <xaudio2.h>

extern "C" {

IXAudio2* pXAudio2 = NULL;
IXAudio2MasteringVoice* pMasterVoice = NULL;

int win_xaudio2_init() {
    HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    if (FAILED(hr)) {
        return -1;
    }

    hr = XAudio2Create(&pXAudio2, 0, XAUDIO2_DEFAULT_PROCESSOR);
    if (FAILED(hr)) {
        CoUninitialize();
        return -2;
    }

    hr = pXAudio2->CreateMasteringVoice(&pMasterVoice);
    if (FAILED(hr)) {
        pXAudio2->Release();
        CoUninitialize();
        return -3;
    }

    return 0;
}

int win_xaudio2_play_pcm(WORD channel_cnt, DWORD sample_rate, BYTE *data_ptr, DWORD data_size) {
    IXAudio2SourceVoice* pSourceVoice;
    WAVEFORMATEX wf = {0};
    XAUDIO2_BUFFER buffer = {0};

    wf.wFormatTag = WAVE_FORMAT_PCM;
    wf.nChannels = channel_cnt;
    wf.nSamplesPerSec = sample_rate;
    wf.wBitsPerSample = 16;
    wf.nBlockAlign = (wf.nChannels * (wf.wBitsPerSample/8));
    wf.nAvgBytesPerSec = wf.nBlockAlign * wf.nSamplesPerSec;

    HRESULT hr = pXAudio2->CreateSourceVoice(&pSourceVoice, &wf);
    if (FAILED(hr)) {
        return -1;
    }

    buffer.AudioBytes = data_size;
    buffer.pAudioData = data_ptr;
    buffer.Flags = XAUDIO2_END_OF_STREAM;

    hr = pSourceVoice->SubmitSourceBuffer(&buffer);
    if (FAILED(hr)) {
        pSourceVoice->DestroyVoice();
        return -2;
    }

    hr = pSourceVoice->Start(0);
    if (FAILED(hr)) {
        pSourceVoice->DestroyVoice();
        return -3;
    }

    XAUDIO2_VOICE_STATE state;
    do {
        pSourceVoice->GetState(&state);
        Sleep(100);
    } while (state.BuffersQueued > 0);

    pSourceVoice->DestroyVoice();

    return 0;
}

void win_xaudio2_deinit() {
    pMasterVoice->DestroyVoice();
    pXAudio2->Release();
    CoUninitialize();
}

}