// ##############################################################################################
//   Author:        DsChAeK
//   URL:           http://www.dschaek.de
//   Projekt:       uTLibVLC
//   Lizenz:        Freeware
//   Version:       v2.4
//
//   Aufgabe:       Wrapper for LibVLC v1.1 (or higher)
//
//   Info:          based on some code from TheUnknownOnes (good work!)
//
//   Lizenz:        Copyright (c) 2009, DsChAeK
//
//                  Permission to use, copy, modify, and/or distribute this software for any purpose
//                  with or without fee is hereby granted, provided that the above copyright notice
//                  and this permission notice appear in all copies.
//
//                  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//                  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//                  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//                  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//                  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//                  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
// ##############################################################################################
//
//   Changelog:
//     04.01.2015, DsChAeK, v2.4 for VLC 2.x Only
//       -adaptions for Embercado XE6
//       -new functions:  VLC_GetCropMode,VLC_SetARMode,VLC_SetChannel,VLC_GetChannel
//       -fixed marquee string
//       -events are working
//
//     03.02.2012, DsChAeK, v2.3 for VLC 2.x Only
//       -Logging API is deprecated and not working anymore...there is no alternative!
//
//     02.07.2011, DsChAeK, v2.2
//       -events are working now!(thx to Jurassic Pork)
//        -> all events are registered to FCallback
//        -> you can use FUserdata if needed (not tested by me)
//        -> updated event records/types/constants
//        -> added VLC_GetEventString()      
//       -removed property: Fullscreen -> IsFullscreen already exists
//       -added a few more comments
//
//     30.05.2011, DsChAeK, v2.1
//       -added OnLogTimer() instead of VLC_AppendLastLogMsgs()
//       -added up2date event codes as comment
//       -added libvlc_test_event for testing events (not working!)
//
//     07.04.2011, DsChAeK, v2.0
//       -added constant arrays for mux/vcodecs/acodecs which are offered by VLC GUI
//       -added VLC_SetMute()/VLC_GetMute()
//       -removed VLC_ToggleMute()
//       -added VLC_SetMarquee()
//
//     15.02.2011, DsChAeK
//       -VLC_GetAudioTrackList(): get real track order and ids
//        ->duplicated http ts streams have random track orders 
//          compared to the original stream! -> VLC BUG
//       
//     06.02.2011, DsChAeK
//       -real stay on top 
//       -toggle fullscreen with TFrame-object
//       -VLC_Stop() returns if really stopped
//       -set background panel for fullscreen form
//
//     30.10.2010, DsChAeK
//       -fixed fullscreen toggle with multi-monitor
//
//     24.10.2010, DsChAeK
//       -if one instance toggled to fullscreen and another wants to switch back
//        it needs to know some parameters which I made public.
//        handling between instances is on your side.
//       -disabled events, new version crashes again... :)
//
//     24.08.2010, DsChAeK
//       -added adjust video functions
//       -new functions -> VLC_PlayMedia()/VLC_StopMedia()
//       -enabled events, no crash anymore, but it's still not working
//
//     01.06.2010, DsChAeK
//       -adaptions for LibVLC v1.1
//       -replaced ILibVLC through TLibVLC, each object loads its own libvlc.dll!
//        ->not so many locations to adapt if a function changes
//        ->libvlc functions and own functions like e.g. VLC_Play() are handled in one class
//       -support of registered/custom vlc path, no need to copy vlc files into the app folder
//       -removed version check
//       -libvlc_vprinterr/libvlc_printerr not implemented, delphi don't handle var_args by default and no need
//       -fullscreen toggle through own TForm, no vlc window to handle
//        (since libVLC 1.1 you have to handle this by yourself, there are als no vlc hotkeys in fullscreen anymore!)
//
// ##############################################################################################
//
//  TODO: -events are not working
//
// ##############################################################################################
{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit uTLibVLC;

interface

uses
  sysUtils, windows, controls, Math,

  classes, extctrls, forms;

const
  ChrCRLF = ^M^J;

  // MUX (Name + Mux + FileExtension)
  MAX_FORMAT_MUX = 13;
  MUX_NameMuxExt : array[0..12, 0..2] of String = (
                                                    ('MPEG-TS','ts','.ts'),
                                                    ('MPEG-PS','ps','.ps'),
                                                    ('MPEG1','mpeg1','.mpeg1'),
                                                    ('ASF/WMV','asf','.asf'),
                                                    ('WEBM','webm','.webm'),
                                                    ('MJPEG','mpjpeg','.mjpeg'),
                                                    ('MKV','mkv','.mkv'),
                                                    ('OGG/OGM','ogg','.ogm'),
                                                    ('WAV','wav','.wav'),
                                                    ('MP3','raw','.mp3'),
                                                    ('MP4/MOV','mp4','.mp4'),
                                                    ('FLV','flv','.flv'),
                                                    ('AVI','avi','.avi')
                                                  );
  // VIDEO CODEC (Name + Codec)
  MAX_FORMAT_VCODEC = 14;
  VCODEC_NameCodec : array[0..13, 0..1] of String = (
                                                      ('MPEG-1','mp1v'),
                                                      ('MPEG-2','mp2v'),
                                                      ('MPEG-4','mp4v'),
                                                      ('DIVX 1','DIV1'),
                                                      ('DIVX 2','DIV2'),
                                                      ('DIVX 3','DIV3'),
                                                      ('H-263','H263'),
                                                      ('H-264','h264'),
                                                      ('VP8','VP80'),
                                                      ('WMV1','WMV1'),
                                                      ('WMV2','WMV2'),
                                                      ('M-JPEG','MJPG'),
                                                      ('Theora','theo'),
                                                      ('Dirac','drac')
                                                    );

  // AUDIO CODEC (Name + Codec)
  MAX_FORMAT_ACODEC = 9;
  ACODEC_NameCodec : array[0..8, 0..1] of String = (
                                                      ('MPEG Audio','mpga'),
                                                      ('MP3','mp3'),
                                                      ('MPEG 4 Audio (AAC)','mp4v'),
                                                      ('A52/AC-3','a52'),
                                                      ('Vorbis','vorb'),
                                                      ('Flac','flac'),
                                                      ('Speex','spx'),
                                                      ('WAV','s16l'),
                                                      ('WMA2','wma2')
                                                    );


type
  Plibvlc_instance_t = type Pointer;

  libvlc_time_t = Int64;

  libvlc_playlist_item_t = record
    i_id : Integer;
    psz_uri : PAnsiChar;
    psz_name : PAnsiChar;
  end;

  Plibvlc_playlist_item_t = ^libvlc_playlist_item_t;

  Plibvlc_log_t = type Pointer;

  Plibvlc_log_iterator_t = type Pointer;

  libvlc_log_message_t = record
    sizeof_msg : Cardinal;   // sizeof() of message structure, must be filled in by user
    i_severity : Integer;    // 0=INFO, 1=ERR, 2=WARN, 3=DBG
    psz_type,                // module type
    psz_name,                // module name
    psz_header,              // optional header
    psz_message : PAnsiChar; // message
  end;

  Plibvlc_log_message_t = ^libvlc_log_message_t;

  Plibvlc_event_manager_t = type Pointer;

type  
  libvlc_event_type_t = Integer;

const
  libvlc_MediaMetaChanged              = $0;
  libvlc_MediaSubItemAdded             = $1;
  libvlc_MediaDurationChanged          = $2;
  libvlc_MediaParsedChanged            = $3;
  libvlc_MediaFreed                    = $4;
  libvlc_MediaStateChanged             = $5;

  libvlc_MediaPlayerMediaChanged       = $100;
  libvlc_MediaPlayerNothingSpecial     = $101;
  libvlc_MediaPlayerOpening            = $102;
  libvlc_MediaPlayerBuffering          = $103;
  libvlc_MediaPlayerPlaying            = $104;
  libvlc_MediaPlayerPaused             = $105;
  libvlc_MediaPlayerStopped            = $106;
  libvlc_MediaPlayerForward            = $107;
  libvlc_MediaPlayerBackward           = $108;
  libvlc_MediaPlayerEndReached         = $109;
  libvlc_MediaPlayerEncounteredError   = $110;
  libvlc_MediaPlayerTimeChanged        = $111;
  libvlc_MediaPlayerPositionChanged    = $112;
  libvlc_MediaPlayerSeekableChanged    = $113;
  libvlc_MediaPlayerPausableChanged    = $114;
  libvlc_MediaPlayerTitleChanged       = $115;
  libvlc_MediaPlayerSnapshotTaken      = $116;
  libvlc_MediaPlayerLengthChanged      = $117;

  libvlc_MediaListItemAdded            = $200;
  libvlc_MediaListWillAddItem          = $201;
  libvlc_MediaListItemDeleted          = $202;
  libvlc_MediaListWillDeleteItem       = $203;

  libvlc_MediaListViewItemAdded        = $300;
  libvlc_MediaListViewWillAddItem      = $301;
  libvlc_MediaListViewItemDeleted      = $302;
  libvlc_MediaListViewWillDeleteItem   = $303;

  libvlc_MediaListPlayerPlayed         = $400;
  libvlc_MediaListPlayerNextItemSet    = $401;
  libvlc_MediaListPlayerStopped        = $402;

  libvlc_MediaDiscovererStarted        = $500;
  libvlc_MediaDiscovererEnded          = $501;

  libvlc_VlmMediaAdded                 = $600;
  libvlc_VlmMediaRemoved               = $601;
  libvlc_VlmMediaChanged               = $602;
  libvlc_VlmMediaInstanceStarted       = $603;
  libvlc_VlmMediaInstanceStopped       = $604;
  libvlc_VlmMediaInstanceStatusInit    = $605;
  libvlc_VlmMediaInstanceStatusOpening = $606;
  libvlc_VlmMediaInstanceStatusPlaying = $607;
  libvlc_VlmMediaInstanceStatusPause   = $608;
  libvlc_VlmMediaInstanceStatusEnd     = $609;
  libvlc_VlmMediaInstanceStatusError   = $610;

const
  libvlc_events : array[0..47] of Integer = (
                                              libvlc_MediaMetaChanged              ,
                                              libvlc_MediaSubItemAdded             ,
                                              libvlc_MediaDurationChanged          ,
                                              libvlc_MediaParsedChanged            ,
                                              libvlc_MediaFreed                    ,
                                              libvlc_MediaStateChanged             ,

                                              libvlc_MediaPlayerMediaChanged       ,
                                              libvlc_MediaPlayerNothingSpecial     ,
                                              libvlc_MediaPlayerOpening            ,
                                              libvlc_MediaPlayerBuffering          ,
                                              libvlc_MediaPlayerPlaying            ,
                                              libvlc_MediaPlayerPaused             ,
                                              libvlc_MediaPlayerStopped            ,
                                              libvlc_MediaPlayerForward            ,
                                              libvlc_MediaPlayerBackward           ,
                                              libvlc_MediaPlayerEndReached         ,
                                              libvlc_MediaPlayerEncounteredError   ,
                                              libvlc_MediaPlayerTimeChanged        ,
                                              libvlc_MediaPlayerPositionChanged    ,
                                              libvlc_MediaPlayerSeekableChanged    ,
                                              libvlc_MediaPlayerPausableChanged    ,
                                              libvlc_MediaPlayerTitleChanged       ,
                                              libvlc_MediaPlayerSnapshotTaken      ,
                                              libvlc_MediaPlayerLengthChanged      ,

                                              libvlc_MediaListItemAdded            ,
                                              libvlc_MediaListWillAddItem          ,
                                              libvlc_MediaListItemDeleted          ,
                                              libvlc_MediaListWillDeleteItem       ,

                                              libvlc_MediaListViewItemAdded        ,
                                              libvlc_MediaListViewWillAddItem      ,
                                              libvlc_MediaListViewItemDeleted      ,
                                              libvlc_MediaListViewWillDeleteItem   ,

                                              libvlc_MediaListPlayerPlayed         ,
                                              libvlc_MediaListPlayerNextItemSet    ,
                                              libvlc_MediaListPlayerStopped        ,
                                                                             
                                              libvlc_MediaDiscovererStarted        ,
                                              libvlc_MediaDiscovererEnded          ,

                                              libvlc_VlmMediaAdded                 ,
                                              libvlc_VlmMediaRemoved               ,
                                              libvlc_VlmMediaChanged               ,
                                              libvlc_VlmMediaInstanceStarted       ,
                                              libvlc_VlmMediaInstanceStopped       ,
                                              libvlc_VlmMediaInstanceStatusInit    ,
                                              libvlc_VlmMediaInstanceStatusOpening ,
                                              libvlc_VlmMediaInstanceStatusPlaying ,
                                              libvlc_VlmMediaInstanceStatusPause   ,
                                              libvlc_VlmMediaInstanceStatusEnd     ,
                                              libvlc_VlmMediaInstanceStatusError
                                             );

  libvlc_events_text : array[0..47] of String = (
                                              'libvlc_MediaMetaChanged'              ,
                                              'libvlc_MediaSubItemAdded'             ,
                                              'libvlc_MediaDurationChanged'          ,
                                              'libvlc_MediaParsedChanged'            ,
                                              'libvlc_MediaFreed'                    ,
                                              'libvlc_MediaStateChanged'             ,

                                              'libvlc_MediaPlayerMediaChanged'       ,
                                              'libvlc_MediaPlayerNothingSpecial'     ,
                                              'libvlc_MediaPlayerOpening'            ,
                                              'libvlc_MediaPlayerBuffering'          ,
                                              'libvlc_MediaPlayerPlaying'            ,
                                              'libvlc_MediaPlayerPaused'             ,
                                              'libvlc_MediaPlayerStopped'            ,
                                              'libvlc_MediaPlayerForward'            ,
                                              'libvlc_MediaPlayerBackward'           ,
                                              'libvlc_MediaPlayerEndReached'         ,
                                              'libvlc_MediaPlayerEncounteredError'   ,
                                              'libvlc_MediaPlayerTimeChanged'        ,
                                              'libvlc_MediaPlayerPositionChanged'    ,
                                              'libvlc_MediaPlayerSeekableChanged'    ,
                                              'libvlc_MediaPlayerPausableChanged'    ,
                                              'libvlc_MediaPlayerTitleChanged'       ,
                                              'libvlc_MediaPlayerSnapshotTaken'      ,
                                              'libvlc_MediaPlayerLengthChanged'      ,

                                              'libvlc_MediaListItemAdded'            ,
                                              'libvlc_MediaListWillAddItem'          ,
                                              'libvlc_MediaListItemDeleted'          ,
                                              'libvlc_MediaListWillDeleteItem'       ,

                                              'libvlc_MediaListViewItemAdded'        ,
                                              'libvlc_MediaListViewWillAddItem'      ,
                                              'libvlc_MediaListViewItemDeleted'      ,
                                              'libvlc_MediaListViewWillDeleteItem'   ,

                                              'libvlc_MediaListPlayerPlayed'         ,
                                              'libvlc_MediaListPlayerNextItemSet'    ,
                                              'libvlc_MediaListPlayerStopped'        ,
                                              
                                              'libvlc_MediaDiscovererStarted'        ,
                                              'libvlc_MediaDiscovererEnded'          ,

                                              'libvlc_VlmMediaAdded'                 ,
                                              'libvlc_VlmMediaRemoved'               ,
                                              'libvlc_VlmMediaChanged'               ,
                                              'libvlc_VlmMediaInstanceStarted'       ,
                                              'libvlc_VlmMediaInstanceStopped'       ,
                                              'libvlc_VlmMediaInstanceStatusInit'    ,
                                              'libvlc_VlmMediaInstanceStatusOpening' ,
                                              'libvlc_VlmMediaInstanceStatusPlaying' ,
                                              'libvlc_VlmMediaInstanceStatusPause'   ,
                                              'libvlc_VlmMediaInstanceStatusEnd'     ,
                                              'libvlc_VlmMediaInstanceStatusError'
                                             );
                                             
type

  Plibvlc_media_t = type Pointer;

  libvlc_meta_t = (libvlc_meta_Title,
                    libvlc_meta_Artist,
                    libvlc_meta_Genre,
                    libvlc_meta_Copyright,
                    libvlc_meta_Album,
                    libvlc_meta_TrackNumber,
                    libvlc_meta_Description,
                    libvlc_meta_Rating,
                    libvlc_meta_Date,
                    libvlc_meta_Setting,
                    libvlc_meta_URL,
                    libvlc_meta_Language,
                    libvlc_meta_NowPlaying,
                    libvlc_meta_Publisher,
                    libvlc_meta_EncodedBy,
                    libvlc_meta_ArtworkURL,
                    libvlc_meta_TrackID);

  libvlc_state_t = (libvlc_NothingSpecial,
                    libvlc_Opening,
                    libvlc_Buffering,
                    libvlc_Playing,
                    libvlc_Paused,
                    libvlc_Stopped,
                    libvlc_Ended,
                    libvlc_Error);

const
  libvlc_media_option_trusted = $2;
  libvlc_media_option_unique = $100;

  libvlc_position_disable = 0;
  libvlc_position_center = 1;
  libvlc_position_left = 2;
  libvlc_position_right = 3;
  libvlc_position_top = 4;
  libvlc_position_top_left = 5;
  libvlc_position_top_right = 6;
  libvlc_position_bottom = 7;
  libvlc_position_bottom_left = 8;
  libvlc_position_bottom_right = 9;

  libvlc_position : array[0..9] of Integer = (
    libvlc_position_disable,
    libvlc_position_center,
    libvlc_position_left,
    libvlc_position_right,
    libvlc_position_top,
    libvlc_position_top_left,
    libvlc_position_top_right,
    libvlc_position_bottom,
    libvlc_position_bottom_left,
    libvlc_position_bottom_right
  );

type
  libvlc_video_marquee_option_t = (
    libvlc_marquee_Enabled,
    libvlc_marquee_Text,
    libvlc_marquee_Color,
    libvlc_marquee_Opacity,
    libvlc_marquee_Position,
    libvlc_marquee_Refresh,
    libvlc_marquee_Size,
    libvlc_marquee_Timeout,
    libvlc_marquee_X,
    libvlc_marquee_Y
  );

  libvlc_video_logo_option_t = (
    libvlc_logo_enable,
    libvlc_logo_file,
    libvlc_logo_x,
    libvlc_logo_y,
    libvlc_logo_delay,
    libvlc_logo_repeat,
    libvlc_logo_opacity,
    libvlc_logo_position
  );

  libvlc_video_adjust_option_t = (
    libvlc_adjust_Enable ,
    libvlc_adjust_Contrast,
    libvlc_adjust_Brightness,
    libvlc_adjust_Hue,
    libvlc_adjust_Saturation,
    libvlc_adjust_Gamma
  );

  libvlc_playback_mode_t = (
    libvlc_playback_mode_default,
    libvlc_playback_mode_loop,
    libvlc_playback_mode_repeat
  );

  type
    libvlc_track_type_t = Integer;

  const
    libvlc_track_unknown   = -1;
    libvlc_track_audio     = 0;
    libvlc_track_video     = 1;
    libvlc_track_text      = 2;

    type
    libvlc_media_stats_t = record
      i_read_bytes : Integer;
      f_input_bitrate : Single;

      i_demux_read_bytes : Integer;
      f_demux_bitrate : Single;
      i_demux_corrupted : Integer;
      i_demux_discontinuity : Integer;

      i_decoded_video : Integer;
      i_decoded_audio : Integer;

      i_displayed_pictures : Integer;
      i_lost_pictures : Integer;

      i_played_abuffers : Integer;
      i_lost_abuffers : Integer;

      i_sent_packets : Integer;
      i_sent_bytes : Integer;
      f_send_bitrate : Single;
    end;
    Plibvlc_media_stats_t = ^libvlc_media_stats_t;

  type
  Plibvlc_media_list_t = type Pointer;

  Plibvlc_media_library_t = type Pointer;

  Plibvlc_media_player_t = type Pointer;

  Plibvlc_track_description_t = ^libvlc_track_description_t;
  libvlc_track_description_t = record
    i_id : Integer;
    psz_name : PAnsiChar;
    p_next : Plibvlc_track_description_t;
  end;

  Plibvlc_audio_output_t = ^libvlc_audio_output_t;
  libvlc_audio_output_t = record
    psz_name : PAnsiChar;
    pst_description : PAnsiChar;
    p_next : Plibvlc_audio_output_t;
  end;

  libvlc_rectangle_t = record
    top, left,
    bottom, right : Integer;
  end;
  Plibvlc_rectangle_t = ^libvlc_rectangle_t;

  type
    libvlc_audio_output_device_types_t = Integer;
  const
    libvlc_AudioOutputDevice_Error  = -1;
    libvlc_AudioOutputDevice_Mono   =  1;
    libvlc_AudioOutputDevice_Stereo =  2;
    libvlc_AudioOutputDevice_2F2R   =  4;
    libvlc_AudioOutputDevice_3F2R   =  5;
    libvlc_AudioOutputDevice_5_1    =  6;
    libvlc_AudioOutputDevice_6_1    =  7;
    libvlc_AudioOutputDevice_7_1    =  8;
    libvlc_AudioOutputDevice_SPDIF  = 10;

  type
    libvlc_audio_output_channel_t = Integer;
  const
    libvlc_AudioChannel_Error   = -1;
    libvlc_AudioChannel_Stereo  =  1;
    libvlc_AudioChannel_RStereo =  2;
    libvlc_AudioChannel_Left    =  3;
    libvlc_AudioChannel_Right   =  4;
    libvlc_AudioChannel_Dolbys  =  5;

  type
  Plibvlc_media_list_player_t = type Pointer;

  Tmedia_meta_changed = record
    meta_type : libvlc_meta_t;
  end;

  Tmedia_subitem_added = record
    new_child : Plibvlc_media_t;
  end;

  Tmedia_duration_changed = record
    new_duration : Int64;
  end;

  Tmedia_preparsed_changed = record
    new_status : Integer;
  end;

  Tmedia_freed = record
    md : Plibvlc_media_t;
  end;

  Tmedia_state_changed = record
    new_state : libvlc_state_t;
  end;

  Tmedia_player_buffering = record
    new_cache : Single;
  end;
      
  Tmedia_player_position_changed = record
    new_position : Single;
  end;

  Tmedia_player_time_changed = record
    new_time : libvlc_time_t;
  end;

  Tmedia_player_title_changed = record
    new_title : Integer;
  end;

  Tmedia_player_seekable_changed = record
    new_seekable : Int64;
  end;

  Tmedia_player_pausable_changed = record
    new_pausable : Int64;
  end;

  Tmedia_list_item_added = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_will_add_item = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_item_deleted = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_will_delete_item = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_player_next_item_set = record
    item : Plibvlc_media_t;
  end;

  Tmedia_player_snapshot_taken = record
    psz_filename : PAnsiChar;
  end;

  Tmedia_list_view_item_added = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_view_will_add_item = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_view_item_deleted = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_list_view_will_delete_item = record
    item : Plibvlc_media_t;
    index : Integer;
  end;

  Tmedia_player_length_changed = record
    new_length : libvlc_time_t;
  end;

  Tvlm_media_event = record
    psz_media_name : PAnsiChar;
    psz_instance_name : PAnsiChar;
  end;

  Tmedia_player_media_changed = record
    new_media : Plibvlc_media_t;
  end;

  libvlc_event_t = record
    _type : libvlc_event_type_t;
    p_obj : Pointer;
    case Integer of
      0 : (media_meta_changed : Tmedia_meta_changed);
      1 : (media_subitem_added : Tmedia_subitem_added);
      2 : (media_duration_changed : Tmedia_duration_changed);
      3 : (media_preparsed_changed : Tmedia_preparsed_changed);
      4 : (media_freed : Tmedia_freed);
      5 : (media_state_changed : Tmedia_state_changed);
      6 : (media_player_buffering : Tmedia_player_buffering);
      7 : (media_player_position_changed : Tmedia_player_position_changed);
      8 : (media_player_time_changed : Tmedia_player_time_changed);
      9 : (media_player_title_changed : Tmedia_player_title_changed);
      10: (media_player_seekable_changed : Tmedia_player_seekable_changed);
      11: (media_player_pausable_changed : Tmedia_player_pausable_changed);
      12: (media_list_item_added : Tmedia_list_item_added);
      13: (media_list_will_add_item : Tmedia_list_will_add_item);
      14: (media_list_item_deleted : Tmedia_list_item_deleted);
      15: (media_list_will_delete_item : Tmedia_list_will_delete_item);
      16: (media_list_player_next_item_set : Tmedia_list_player_next_item_set);
      17: (media_player_snapshot_taken : Tmedia_player_snapshot_taken);
      18: (media_player_length_changed : Tmedia_player_length_changed);
      19: (vlm_media_event : Tvlm_media_event);
      20: (media_player_media_changed : Tmedia_player_media_changed);
  end;

  Plibvlc_event_t = ^libvlc_event_t;

  libvlc_callback_t = procedure(p_event : Pointer; userdata : Pointer); cdecl;

  Plibvlc_media_discoverer_t = type Pointer;

type
  // form for fullscreen display
  TFormFS = class(TForm)
    procedure CreateParams(var Params: TCreateParams);override;
  end;

type
  // log event 
  TLogEvent = procedure(const log_message: libvlc_log_message_t) of object;

type
  // main class
  TLibVLC = class(TObject)
    private
      FName         : String;                 // name for instance
      FVersion      : String;                 // version as string

      FDllHandle    : Integer;                // dll handle
      FLib          : Plibvlc_instance_t;     // libvlc instance
      FLastError    : Integer;                // last error

      FLog          : Plibvlc_log_t;          // log
      FLogTimer     : TTimer;                 // log timer
      FLogEvent     : TLogEvent;              // log event
      
      FPlayer       : Plibvlc_media_player_t; // media_player
      FMedia        : Plibvlc_media_t;        // media
      FMediaURL     : String;                 // media url
      FMediaOpt     : TStringList;            // media options
      FStats        : libvlc_media_stats_t;   // stats
      
      FPnlOutput    : TPanel;                 // panel for video output
      FFormFS       : TFormFS;                // form for video fullscreen display
      FFullscreen   : Boolean;                // true=fullscreen false=window

      FOldPanTop    : Integer;                // orig panel pos
      FOldPanLeft   : Integer;                // orig panel pos
      FOldPanHeight : Integer;                // orig panel pos
      FOldPanWidth  : Integer;                // orig panel pos

      FCallback     : Pointer;                // callback pointer for events
      FUserdata     : Pointer;                // pointer for events userdata
      
      FBackground   : TPanel;                 // background for fullscreen mode
      FBackgroundParent : TWinControl;        // parent from background panel       

      // internal functions
      function  GetAProcAddress( var Addr : Pointer; Name : PChar) : Integer;
      procedure LoadFunctions;

      function  SetAParent(hWndChild, hWndNewParent: HWND; NewParentWidth, NewParentHeight: integer): boolean;
      procedure OnLogTimer(Sender: TObject);

    public

      // public functions
      constructor Create(InstName, DLL : String; Params : array of PAnsiChar; ParamsCount:Integer ;LogLevel : Integer; PnlOutput : TPanel; Callback, Userdata : Pointer); overload;
      destructor  Destroy(); override;

      function  VLC_GetLibPath : String;
      function  VLC_GetVersion() : String;

      procedure VLC_PlayMedia(MediaURL: String; MediaOptions : TStringList; Panel : TPanel);
      procedure VLC_StopMedia();

      procedure VLC_Play();
      procedure VLC_Stop();
      procedure VLC_Pause();
      function  VLC_IsPlaying(): Boolean;

      procedure VLC_TakeSnapshot(Path : String; width, height : Integer);
      procedure VLC_SetDeinterlaceMode(Mode : String);
      procedure VLC_SetCropMode(Mode : String);
      function  VLC_GetCropMode() : String;
      procedure VLC_SetARMode(Mode : String);
      function  VLC_GetARMode() : String;
      procedure VLC_ToggleFullscreen(Panel : TPanel; Background: TPanel);overload;virtual;
      procedure VLC_ToggleFullscreen(Frame : TFrame; Background: TPanel);overload;

      procedure VLC_SetChannel(Channel : Integer);
      function  VLC_GetChannel() : Integer;

      procedure VLC_SetAudioTrack(iTrack : Integer);
      function  VLC_GetAudioTrack() : Integer;
      function  VLC_GetAudioTrackList() : String;
      procedure VLC_SetMute(Activate : Boolean);
      function  VLC_GetMute() : Boolean;
      procedure VLC_SetVolume(Level : Integer);
      function  VLC_GetVolume() : Integer;

      function  VLC_GetStats() : libvlc_media_stats_t;
      function  VLC_GetEventString(event : libvlc_event_t): String;
      
      procedure VLC_AdjustVideo(Contrast: Double; Brightness : Double; Hue : Integer; Saturation : Double; Gamma : Double);
      procedure VLC_ResetVideo();
      procedure VLC_SetMarquee(Text : String; Color, Opac, Pos, Refresh, Size, Timeout, X, Y : Integer);
      procedure VLC_SetLogo(LogoFile : string);

      // properties
      property  OldPanTop   : Integer read FOldPanTop    write FOldPanTop;    // video panel top before fullscreen
      property  OldPanLeft  : Integer read FOldPanLeft   write FOldPanLeft;   // video panel left before fullscreen
      property  OldPanHeight: Integer read FOldPanHeight write FOldPanHeight; // video panel height before fullscreen
      property  OldPanWidth : Integer read FOldPanWidth  write FOldPanWidth;  // video panel width before fullscreen
      property  PnlOutput : TPanel read FPnlOutput  write FPnlOutput;         // video panel
      property  FormFS : TFormFS read FFormFS  write FFormFS;                 // fullscreen form
      property  IsFullscreen : Boolean read FFullscreen  write FFullscreen;   // fullscreen indicator
      property  OnLog: TLogEvent read FLogEvent write FLogEvent;              // logging callback function

      property  MediaURL: String read FMediaURL;                              // current media url
      property  Version: String read FVersion;                                // vlc version

    public
      // libvlc functions
      libvlc_playlist_play : procedure (p_instance : Plibvlc_instance_t;
                                         i_id : Integer;
                                         i_options : Integer;
                                         ppsz_options : PAnsiChar); cdecl;
      libvlc_errmsg : function () : PAnsiChar; cdecl;
      libvlc_clearerr : procedure (); cdecl;
      libvlc_new : function(argc : Integer;
                             argv : PAnsiChar) : Plibvlc_instance_t; cdecl;
      libvlc_release : procedure(p_instance : Plibvlc_instance_t); cdecl;
      libvlc_retain : procedure(p_instance : Plibvlc_instance_t); cdecl;
      libvlc_add_intf : procedure(p_instalce : Plibvlc_instance_t;
                                   name : PAnsiChar); cdecl;
      libvlc_wait : procedure(p_instance : Plibvlc_instance_t); cdecl;
      libvlc_get_version : function() : PAnsiChar; cdecl;
      libvlc_get_compiler : function() : PAnsiChar; cdecl;
      libvlc_get_changeset : function() : PAnsiChar; cdecl;

      libvlc_event_attach : procedure(p_event_manager : Plibvlc_event_manager_t;
                                       event_type : libvlc_event_type_t;
                                       f_callback : libvlc_callback_t;
                                       userdata : Pointer); cdecl;
      libvlc_event_detach : procedure(p_event_manager : Plibvlc_event_manager_t;
                                       event_type : libvlc_event_type_t;
                                       f_callback : libvlc_callback_t;
                                       userdata : Pointer); cdecl;
      libvlc_event_type_name : function(event_type : libvlc_event_type_t) : PAnsiChar; cdecl;

      libvlc_get_log_verbosity : function(p_instance : Plibvlc_instance_t) : Cardinal; cdecl;
      libvlc_set_log_verbosity : procedure(p_instance : Plibvlc_instance_t;
                                            level : Cardinal); cdecl;
      libvlc_log_open : function(p_instance : Plibvlc_instance_t) : Plibvlc_log_t; cdecl;
      libvlc_log_close : procedure(p_log : Plibvlc_log_t); cdecl;
      libvlc_log_count : function(p_log : Plibvlc_log_t) : Cardinal; cdecl;
      libvlc_log_clear : procedure(p_log : Plibvlc_log_t); cdecl;
      libvlc_log_get_iterator : function(p_log : Plibvlc_log_t) : Plibvlc_log_iterator_t; cdecl;
      libvlc_log_iterator_free : procedure(p_iter : Plibvlc_log_iterator_t); cdecl;
      libvlc_log_iterator_has_next : function(p_iter : Plibvlc_log_iterator_t) : Integer; cdecl;
      libvlc_log_iterator_next : function(p_iter : Plibvlc_log_iterator_t;
                                           p_buffer : Plibvlc_log_message_t) : Plibvlc_log_message_t; cdecl;

      libvlc_media_new_location : function(p_instance : Plibvlc_instance_t;
                                            psz_mrl : PAnsiChar) : Plibvlc_media_t; cdecl;
      libvlc_media_new_path : function(p_instance : Plibvlc_instance_t;
                                            path : PAnsiChar) : Plibvlc_media_t; cdecl;

      libvlc_media_new_as_node : function(p_instance : Plibvlc_instance_t;
                                           psz_name : PAnsiChar) : Plibvlc_media_t; cdecl;
      libvlc_media_add_option : procedure(p_media : Plibvlc_media_t;
                                           ppsz_options : PAnsiChar); cdecl;
      libvlc_media_retain : procedure(p_media : Plibvlc_media_t); cdecl;
      libvlc_media_release : procedure(p_media : Plibvlc_media_t); cdecl;
      libvlc_media_get_mrl : function(p_media : Plibvlc_media_t) : PAnsiChar; cdecl;
      libvlc_media_duplicate : function(p_media : Plibvlc_media_t) : Plibvlc_media_t; cdecl;
      libvlc_media_get_meta : function(p_media : Plibvlc_media_t;
                                        e_meta : libvlc_meta_t) : PAnsiChar; cdecl;
      libvlc_media_get_state : function(p_media : Plibvlc_media_t) : libvlc_state_t; cdecl;
      libvlc_media_get_stats : function (p_media : Plibvlc_media_t;
                                         p_stats : Plibvlc_media_stats_t) : Integer; cdecl;

      libvlc_media_subitems : function(p_media : Plibvlc_media_t) : Plibvlc_media_list_t; cdecl;
      libvlc_media_event_manager : function(p_media : Plibvlc_media_t) : Plibvlc_event_manager_t; cdecl;
      libvlc_media_get_duration : function(p_media : Plibvlc_media_t) : libvlc_time_t; cdecl;
      libvlc_media_parse : procedure(p_media : Plibvlc_media_t); cdecl;
      libvlc_media_parse_async : procedure(p_media : Plibvlc_media_t); cdecl;
      libvlc_media_is_parsed : procedure(p_media : Plibvlc_media_t); cdecl;
      libvlc_media_set_user_data : procedure(p_media : Plibvlc_media_t;
                                              p_new_user_data : Pointer); cdecl;
      libvlc_media_get_user_data : function(p_media : Plibvlc_media_t) : Pointer; cdecl;

      libvlc_media_list_new : function(p_instance : Plibvlc_instance_t) : Plibvlc_media_list_t; cdecl;
      libvlc_media_list_release : procedure(p_media_list : Plibvlc_media_list_t); cdecl;
      libvlc_media_list_retain : procedure(p_media_list : Plibvlc_media_list_t); cdecl;
      libvlc_media_list_set_media : procedure(p_media_list : Plibvlc_media_list_t;
                                               p_media : Plibvlc_media_t); cdecl;
      libvlc_media_list_media : function(p_media_list : Plibvlc_media_list_t) : Plibvlc_media_t; cdecl;
      libvlc_media_list_add_media : procedure(p_media_list : Plibvlc_media_list_t;
                                               p_media : Plibvlc_media_t); cdecl;
      libvlc_media_list_insert_media : procedure(p_media_list : Plibvlc_media_list_t;
                                                  p_media : Plibvlc_media_t;
                                                  index : Integer); cdecl;
      libvlc_media_list_remove_index : procedure(p_media_list : Plibvlc_media_list_t;
                                                  index : Integer); cdecl;
      libvlc_media_list_count : function(p_media_list : Plibvlc_media_list_t) : Integer; cdecl;
      libvlc_media_list_item_at_index : function(p_media_list : Plibvlc_media_list_t;
                                                  index : Integer) : Plibvlc_media_t; cdecl;
      libvlc_media_list_index_of_item : function(p_media_list : Plibvlc_media_list_t;
                                                  p_media : Plibvlc_media_t) : Integer; cdecl;
      libvlc_media_list_is_readonly : function(p_media_list : Plibvlc_media_list_t) : Integer; cdecl;
      libvlc_media_list_lock : procedure(p_media_list : Plibvlc_media_list_t); cdecl;
      libvlc_media_list_unlock : procedure(p_media_list : Plibvlc_media_list_t); cdecl;
      libvlc_media_list_event_manager : function(p_media_list : Plibvlc_media_list_t) : Plibvlc_event_manager_t; cdecl;

      libvlc_media_library_new : function(p_instance : Plibvlc_instance_t) : Plibvlc_media_library_t; cdecl;
      libvlc_media_library_release : procedure(p_mlib : Plibvlc_media_library_t); cdecl;
      libvlc_media_library_retain : procedure(p_mlib : Plibvlc_media_library_t); cdecl;
      libvlc_media_library_load : procedure(p_mlib : Plibvlc_media_library_t); cdecl;
      libvlc_media_library_media_list : function(p_mlib : Plibvlc_media_library_t) : Plibvlc_media_list_t; cdecl;

      libvlc_media_player_new : function(p_instance : Plibvlc_instance_t) : Plibvlc_media_player_t; cdecl;
      libvlc_media_player_new_from_media : function(p_media : Plibvlc_media_t) : Plibvlc_media_player_t; cdecl;
      libvlc_media_player_release : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_retain : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_set_media : procedure(p_media_player : Plibvlc_media_player_t;
                                                 p_media : Plibvlc_media_t); cdecl;
      libvlc_media_player_get_media : function(p_media_player : Plibvlc_media_player_t) : Plibvlc_media_t; cdecl;
      libvlc_media_player_event_manager : function(p_media_player : Plibvlc_media_player_t) : Plibvlc_event_manager_t; cdecl;
      libvlc_media_player_is_playing : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_play : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_pause : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_stop : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_set_nsobject : procedure(p_media_player : Plibvlc_media_player_t;
                                                    drawable : Pointer); cdecl;
      libvlc_media_player_get_nsobject : function(p_media_player : Plibvlc_media_player_t) : Pointer; cdecl;
      libvlc_media_player_set_agl : procedure(p_media_player : Plibvlc_media_player_t;
                                               drawable : Cardinal); cdecl;
      libvlc_media_player_get_agl : function(p_media_player : Plibvlc_media_player_t) : Cardinal; cdecl;
      libvlc_media_player_set_xwindow : procedure(p_media_player : Plibvlc_media_player_t;
                                                   drawable : Cardinal); cdecl;
      libvlc_media_player_get_xwindow : function(p_media_player : Plibvlc_media_player_t) : Cardinal; cdecl;
      libvlc_media_player_set_hwnd : procedure(p_media_player : Plibvlc_media_player_t;
                                                drawable : Pointer); cdecl;
      libvlc_media_player_get_hwnd : function(p_media_player : Plibvlc_media_player_t) : Pointer; cdecl;
      libvlc_media_player_get_length : function(p_media_player : Plibvlc_media_player_t) : libvlc_time_t; cdecl;
      libvlc_media_player_get_time : function(p_media_player : Plibvlc_media_player_t) : libvlc_time_t; cdecl;
      libvlc_media_player_set_time : procedure(p_media_player : Plibvlc_media_player_t;
                                                time : libvlc_time_t); cdecl;
      libvlc_media_player_get_position : function(p_media_player : Plibvlc_media_player_t) : Single; cdecl;
      libvlc_media_player_set_position : procedure(p_media_player : Plibvlc_media_player_t;
                                                    position : Single); cdecl;
      libvlc_media_player_set_chapter : procedure(p_media_player : Plibvlc_media_player_t;
                                                   chapter : Integer); cdecl;
      libvlc_media_player_get_chapter : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_get_chapter_count : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_will_play : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_get_chapter_count_for_title : function(p_media_player : Plibvlc_media_player_t;
                                                                  title : Integer) : Integer; cdecl;
      libvlc_media_player_set_title : procedure(p_media_player : Plibvlc_media_player_t;
                                                 title : Integer); cdecl;
      libvlc_media_player_get_title : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_get_title_count : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_previous_chapter : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_next_chapter : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_player_get_rate : function(p_media_player : Plibvlc_media_player_t) : Single; cdecl;
      libvlc_media_player_set_rate : procedure(p_media_player : Plibvlc_media_player_t;
                                                rate : Single); cdecl;
      libvlc_media_player_get_state : function(p_media_player : Plibvlc_media_player_t) : libvlc_state_t; cdecl;
      libvlc_media_player_get_fps : function(p_media_player : Plibvlc_media_player_t) : Single; cdecl;
      libvlc_media_player_has_vout : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_is_seekable : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_media_player_can_pause : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_track_description_release : procedure(p_track_description : Plibvlc_track_description_t); cdecl;
      libvlc_toggle_fullscreen : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_set_fullscreen : procedure(p_media_player : Plibvlc_media_player_t;
                                         enabled : Integer); cdecl;
      libvlc_get_fullscreen : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;

      libvlc_video_set_deinterlace : procedure(p_media_player : Plibvlc_media_player_t; psz_mode : PChar); cdecl;
      libvlc_video_get_marquee_int: function(p_mi: Plibvlc_media_player_t; option: libvlc_video_marquee_option_t): Integer; cdecl;
      libvlc_video_get_marquee_string: function(p_mi: Plibvlc_media_player_t; option: libvlc_video_marquee_option_t): PAnsiChar; cdecl;
      libvlc_video_set_marquee_int: procedure(p_mi: Plibvlc_media_player_t; option: libvlc_video_marquee_option_t; i_val: Integer); cdecl;
      libvlc_video_set_marquee_string: procedure(p_mi: Plibvlc_media_player_t; option: libvlc_video_marquee_option_t; psz_text: PAnsiChar); cdecl;
      libvlc_video_get_logo_int: function(p_mi: Plibvlc_media_player_t; option: libvlc_video_logo_option_t): Integer; cdecl;
      libvlc_video_set_logo_int: procedure(p_mi: Plibvlc_media_player_t; option: libvlc_video_logo_option_t; value: Integer); cdecl;
      libvlc_video_set_logo_string: procedure(p_mi: Plibvlc_media_player_t; option: libvlc_video_logo_option_t; psz_value: PAnsiChar); cdecl;
      libvlc_video_get_adjust_int: function(p_mi: Plibvlc_media_player_t; option: libvlc_video_adjust_option_t): Integer; cdecl;
      libvlc_video_set_adjust_int: procedure(p_mi: Plibvlc_media_player_t; option: libvlc_video_adjust_option_t; value: Integer); cdecl;
      libvlc_video_get_adjust_float: function(p_mi: Plibvlc_media_player_t; option: libvlc_video_adjust_option_t): Single; cdecl;
      libvlc_video_set_adjust_float: procedure(p_mi: Plibvlc_media_player_t; option: libvlc_video_adjust_option_t; value: Single); cdecl;

      libvlc_video_set_key_input : procedure(p_media_player : Plibvlc_media_player_t;
                                              Activate : Integer); cdecl;
      libvlc_video_set_mouse_input : procedure(p_media_player : Plibvlc_media_player_t;
                                                Activate : Integer); cdecl;
      libvlc_video_get_size : function(p_media_player : Plibvlc_media_player_t;
                                        var num : Integer;
                                        var px : Integer;
                                        var py : Integer) : Integer; cdecl;
      libvlc_video_get_cursor : function(p_media_player : Plibvlc_media_player_t;
                                          var num : Integer;
                                          var px : Integer;
                                          var py : Integer) : Integer; cdecl;
      libvlc_video_get_height : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_get_width : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_get_scale : function(p_media_player : Plibvlc_media_player_t) : Single; cdecl;
      libvlc_video_set_scale : procedure(p_media_player : Plibvlc_media_player_t;
                                          scale : Single); cdecl;
      libvlc_video_get_aspect_ratio : function(p_media_player : Plibvlc_media_player_t) : PAnsiChar; cdecl;
      libvlc_video_set_aspect_ratio : procedure(p_media_player : Plibvlc_media_player_t;
                                                 psz_aspect : PAnsiChar); cdecl;
      libvlc_video_get_spu : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_get_spu_count : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_get_spu_description : function(p_media_player : Plibvlc_media_player_t) : Plibvlc_track_description_t; cdecl;
      libvlc_video_set_spu : procedure(p_media_player : Plibvlc_media_player_t;
                                        i_spu : Integer); cdecl;
      libvlc_video_set_subtitle_file : function(p_media_player : Plibvlc_media_player_t;
                                                 filename : PAnsiChar) : Integer; cdecl;
      libvlc_video_get_title_description : function(p_media_player : Plibvlc_media_player_t) : Plibvlc_track_description_t; cdecl;
      libvlc_video_get_chapter_description : function(p_media_player : Plibvlc_media_player_t;
                                                       title : Integer) : Plibvlc_track_description_t; cdecl;
      libvlc_video_get_crop_geometry : function(p_media_player : Plibvlc_media_player_t) : PAnsiChar; cdecl;
      libvlc_video_set_crop_geometry : procedure(p_media_player : Plibvlc_media_player_t;
                                                  geometry : PAnsiChar); cdecl;
      libvlc_toggle_teletext : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_video_get_teletext : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_set_teletext : procedure(p_media_player : Plibvlc_media_player_t;
                                            page : Integer); cdecl;
      libvlc_video_get_track_count : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_get_track_description : function(p_media_player : Plibvlc_media_player_t) : Plibvlc_track_description_t; cdecl;
      libvlc_video_get_track : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_video_set_track : procedure(p_media_player : Plibvlc_media_player_t;
                                         track : Integer); cdecl;
      libvlc_video_take_snapshot : procedure(p_media_player : Plibvlc_media_player_t;
                                             num : Integer;
                                             filepath : PAnsiChar;
                                             width, height : Integer); cdecl;
      libvlc_audio_output_list_get : function(p_instance : Plibvlc_instance_t) : Plibvlc_audio_output_t; cdecl;
      libvlc_audio_output_list_release : procedure(audio_output_list : Plibvlc_audio_output_t); cdecl;
      libvlc_audio_output_set : function(p_media_player : Plibvlc_media_player_t;
                                         psz_audio_output : PAnsiChar) : Integer; cdecl;
      libvlc_audio_output_device_count : function(p_instance : Plibvlc_instance_t;
                                                  psz_audio_output : PAnsiChar) : Integer; cdecl;
      libvlc_audio_output_device_longname : function(p_instance : Plibvlc_instance_t;
                                                     psz_audio_output : PAnsiChar;
                                                     device : Integer) : PAnsiChar; cdecl;
      libvlc_audio_output_device_id : function(p_instance : Plibvlc_instance_t;
                                               psz_audio_output : PAnsiChar;
                                               device : Integer) : PAnsiChar; cdecl;
      libvlc_audio_output_device_set : procedure(p_media_player : Plibvlc_media_player_t;
                                                 psz_audio_output : PAnsiChar;
                                                 device : PAnsiChar); cdecl;
      libvlc_audio_output_get_device_type : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_audio_output_set_device_type : procedure(p_media_player : Plibvlc_media_player_t;
                                                      device_type : Integer); cdecl;
      libvlc_audio_toggle_mute : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_audio_get_mute : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_audio_set_mute : procedure(p_media_player : Plibvlc_media_player_t;
                                        status : Integer); cdecl;
      libvlc_audio_get_volume : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_audio_set_volume : function(p_media_player : Plibvlc_media_player_t;
                                         volume : Integer) : Integer; cdecl;
      libvlc_audio_get_track_count : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_audio_get_track_description : function(p_media_player : Plibvlc_media_player_t) : Plibvlc_track_description_t; cdecl;
      libvlc_audio_get_track : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_audio_set_track : procedure(p_media_player : Plibvlc_media_player_t; i_track : Integer); cdecl;
      libvlc_audio_get_channel : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
      libvlc_audio_set_channel : procedure(p_media_player : Plibvlc_media_player_t;
                                           channel : Integer); cdecl;

      libvlc_media_list_player_new : function(p_instance : Plibvlc_instance_t) : Plibvlc_media_list_player_t; cdecl;
      libvlc_media_list_player_release : procedure(p_mlp : Plibvlc_media_list_player_t); cdecl;
      libvlc_media_list_player_set_media_player : procedure(p_mlp : Plibvlc_media_list_player_t;
                                                            p_media_player : Plibvlc_media_player_t); cdecl;
      libvlc_media_list_player_set_media_list : procedure(p_mlp : Plibvlc_media_list_player_t;
                                                          p_media_list : Plibvlc_media_list_t); cdecl;
      libvlc_media_list_player_play : procedure(p_mlp : Plibvlc_media_list_player_t); cdecl;
      libvlc_media_list_player_pause : procedure(p_mlp : Plibvlc_media_list_player_t); cdecl;
      libvlc_media_list_player_is_playing : function(p_mlp : Plibvlc_media_list_player_t) : Integer; cdecl;
      libvlc_media_list_player_get_state : function(p_mlp : Plibvlc_media_list_player_t) : libvlc_state_t; cdecl;
      libvlc_media_list_player_play_item_at_index : procedure(p_mlp : Plibvlc_media_list_player_t;
                                                              i_index : Integer); cdecl;
      libvlc_media_list_player_play_item : procedure(p_mlp : Plibvlc_media_list_player_t;
                                                     p_media : Plibvlc_media_t); cdecl;
      libvlc_media_list_player_stop : procedure(p_mlp : Plibvlc_media_list_player_t); cdecl;
      libvlc_media_list_player_next : procedure(p_mlp : Plibvlc_media_list_player_t); cdecl;

      libvlc_media_discoverer_new_from_name : function(p_instance : Plibvlc_instance_t;
                                                        psz_name : PAnsiChar) : Plibvlc_media_discoverer_t; cdecl;
      libvlc_media_discoverer_release : procedure(p_mdis : Plibvlc_media_discoverer_t); cdecl;
      libvlc_media_discoverer_localized_name : function(p_mdis : Plibvlc_media_discoverer_t) : PAnsiChar; cdecl;
      libvlc_media_discoverer_media_list : function(p_mdis : Plibvlc_media_discoverer_t) : Plibvlc_media_list_t; cdecl;
      libvlc_media_discoverer_event_manager : function(p_mdis : Plibvlc_media_discoverer_t) : Plibvlc_event_manager_t; cdecl;
      libvlc_media_discoverer_is_running : function(p_mdis : Plibvlc_media_discoverer_t) : Integer; cdecl;

      libvlc_vlm_release : procedure(p_instance : Plibvlc_instance_t); cdecl;
      libvlc_vlm_add_broadcast : procedure(p_instance : Plibvlc_instance_t;
                                           psz_name,
                                           psz_input,
                                           psz_output : PAnsiChar;
                                           options : Integer;
                                           ppsz_options : Pointer;
                                           b_enabled : Integer;
                                           b_loop : Integer); cdecl;
      libvlc_vlm_add_vod : procedure(p_instance : Plibvlc_instance_t;
                                     psz_name,
                                     psz_input : PAnsiChar;
                                     i_options : Integer;
                                     ppsz_options : Pointer;
                                     b_enabled : Integer;
                                     psz_mux : PAnsiChar); cdecl;
      libvlc_vlm_del_media : procedure(p_instance : Plibvlc_instance_t;
                                       psz_name : PAnsiChar); cdecl;
      libvlc_vlm_set_enabled : procedure(p_instance : Plibvlc_instance_t;
                                         psz_name : PAnsiChar;
                                         b_enabled : Integer); cdecl;
      libvlc_vlm_set_output : procedure(p_instance : Plibvlc_instance_t;
                                        psz_name : PAnsiChar;
                                        psz_output : PAnsiChar); cdecl;
      libvlc_vlm_set_input : procedure(p_instance : Plibvlc_instance_t;
                                       psz_name : PAnsiChar;
                                       psz_input : PAnsiChar); cdecl;
      libvlc_vlm_add_input : procedure(p_instance : Plibvlc_instance_t;
                                       psz_name : PAnsiChar;
                                       pst_input : PAnsiChar); cdecl;
      libvlc_vlm_set_loop : procedure(p_instance : Plibvlc_instance_t;
                                      psz_name : PAnsiChar;
                                      b_loop : Integer); cdecl;
      libvlc_vlm_set_mux : procedure(p_instance : Plibvlc_instance_t;
                                     psz_name : PAnsiChar;
                                     psz_mux : PAnsiChar); cdecl;
      libvlc_vlm_change_media : procedure(p_instance : Plibvlc_instance_t;
                                          psz_name,
                                          psz_input,
                                          psz_output : PAnsiChar;
                                          i_options : Integer;
                                          ppsz_options : Pointer;
                                          b_enabled : Integer;
                                          b_loop : Integer); cdecl;
      libvlc_vlm_play_media : procedure(p_instance : Plibvlc_instance_t;
                                        psz_name : PAnsiChar); cdecl;
      libvlc_vlm_stop_media : procedure(p_instance : Plibvlc_instance_t;
                                        psz_name : PAnsiChar); cdecl;
      libvlc_vlm_pause_media : procedure(p_instance : Plibvlc_instance_t;
                                         psz_name : PAnsiChar); cdecl;
      libvlc_vlm_seek_media : procedure(p_instance : Plibvlc_instance_t;
                                        psz_name : PAnsiChar;
                                        f_percentage : Single); cdecl;
      libvlc_vlm_show_media : function(p_instance : Plibvlc_instance_t;
                                       psz_name : PAnsiChar) : PAnsiChar; cdecl;
      libvlc_vlm_get_media_instance_position : function(p_instance : Plibvlc_instance_t;
                                                        psz_name : PAnsiChar;
                                                        i_instance : Integer) : Single; cdecl;
      libvlc_vlm_get_media_instance_time : function(p_instance : Plibvlc_instance_t;
                                                    psz_name : PAnsiChar;
                                                    i_instance : Integer) : Integer; cdecl;
      libvlc_vlm_get_media_instance_length : function(p_instance : Plibvlc_instance_t;
                                                      psz_name : PAnsiChar;
                                                      i_instance : Integer) : Integer; cdecl;
      libvlc_vlm_get_media_instance_rate : function(p_instance : Plibvlc_instance_t;
                                                    psz_name : PAnsiChar;
                                                    i_instance : Integer) : Integer; cdecl;
(*
      libvlc_vlm_get_media_instance_title : function(p_instance : Plibvlc_instance_t;
                                                     psz_name : PAnsiChar;
                                                     i_instance : Integer) : Integer; cdecl;
      libvlc_vlm_get_media_instance_chapter : function(p_instance : Plibvlc_instance_t;
                                                       psz_name : PAnsiChar;
                                                       i_instance : Integer) : Integer; cdecl;
      libvlc_vlm_get_media_instance_seekable : function(p_instance : Plibvlc_instance_t;
                                                        psz_name : PAnsiChar;
                                                        i_instance : Integer) : Integer; cdecl;
                                                        *)
  end;

implementation

procedure Delay(msDelay: DWORD);
var
  Start : DWORD;
begin
  Start:=GetTickCount;

  repeat
    sleep(2);
    Application.ProcessMessages;
  until GetTickCount-Start > msDelay;
end;

{ TLibVLC }
destructor TLibVLC.Destroy;
// free objects
begin
  libvlc_log_close(FLog);
  libvlc_release(FLib);

  if Assigned(FLogTimer) then
    FLogTimer.Free;
  
  if Assigned(FFormFS) then
    FFormFS.Free;
end;

procedure TLibVLC.LoadFunctions;
// get all function pointers
begin
  GetAProcAddress(@libvlc_playlist_play, 'libvlc_playlist_play');
  GetAProcAddress(@libvlc_errmsg , 'libvlc_errmsg');
  GetAProcAddress(@libvlc_clearerr , 'libvlc_clearerr');

  GetAProcAddress(@libvlc_new , 'libvlc_new');
  GetAProcAddress(@libvlc_release , 'libvlc_release');
  GetAProcAddress(@libvlc_retain , 'libvlc_retain');
  GetAProcAddress(@libvlc_add_intf , 'libvlc_add_intf');
  GetAProcAddress(@libvlc_wait , 'libvlc_wait');
  GetAProcAddress(@libvlc_get_version , 'libvlc_get_version');
  GetAProcAddress(@libvlc_get_compiler , 'libvlc_get_compiler');
  GetAProcAddress(@libvlc_get_changeset , 'libvlc_get_changeset');

  GetAProcAddress(@libvlc_event_attach , 'libvlc_event_attach');
  GetAProcAddress(@libvlc_event_detach , 'libvlc_event_detach');
  GetAProcAddress(@libvlc_event_type_name , 'libvlc_event_type_name');

  GetAProcAddress(@libvlc_get_log_verbosity , 'libvlc_get_log_verbosity');
  GetAProcAddress(@libvlc_set_log_verbosity , 'libvlc_set_log_verbosity');
  GetAProcAddress(@libvlc_log_open , 'libvlc_log_open');
  GetAProcAddress(@libvlc_log_close , 'libvlc_log_close');
  GetAProcAddress(@libvlc_log_count , 'libvlc_log_count');
  GetAProcAddress(@libvlc_log_clear , 'libvlc_log_clear');
  GetAProcAddress(@libvlc_log_get_iterator , 'libvlc_log_get_iterator');
  GetAProcAddress(@libvlc_log_iterator_free , 'libvlc_log_iterator_free');
  GetAProcAddress(@libvlc_log_iterator_has_next , 'libvlc_log_iterator_has_next');
  GetAProcAddress(@libvlc_log_iterator_next , 'libvlc_log_iterator_next');

  GetAProcAddress(@libvlc_media_new_location , 'libvlc_media_new_location');
  GetAProcAddress(@libvlc_media_new_path , 'libvlc_media_new_path');
  GetAProcAddress(@libvlc_media_new_as_node , 'libvlc_media_new_as_node');
  GetAProcAddress(@libvlc_media_add_option , 'libvlc_media_add_option');
  GetAProcAddress(@libvlc_media_retain , 'libvlc_media_retain');
  GetAProcAddress(@libvlc_media_release , 'libvlc_media_release');
  GetAProcAddress(@libvlc_media_get_mrl , 'libvlc_media_get_mrl');
  GetAProcAddress(@libvlc_media_duplicate , 'libvlc_media_duplicate');
  GetAProcAddress(@libvlc_media_get_meta , 'libvlc_media_get_meta');
  GetAProcAddress(@libvlc_media_get_state , 'libvlc_media_get_state');
  GetAProcAddress(@libvlc_media_get_stats , 'libvlc_media_get_stats');
  GetAProcAddress(@libvlc_media_subitems , 'libvlc_media_subitems');
  GetAProcAddress(@libvlc_media_event_manager , 'libvlc_media_event_manager');
  GetAProcAddress(@libvlc_media_get_duration , 'libvlc_media_get_duration');
  GetAProcAddress(@libvlc_media_parse, 'libvlc_media_parse');
  GetAProcAddress(@libvlc_media_parse_async, 'libvlc_media_parse_async');
  GetAProcAddress(@libvlc_media_is_parsed, 'libvlc_media_is_parsed');
  GetAProcAddress(@libvlc_media_set_user_data , 'libvlc_media_set_user_data');
  GetAProcAddress(@libvlc_media_get_user_data , 'libvlc_media_get_user_data');

  GetAProcAddress(@libvlc_media_list_new , 'libvlc_media_list_new');
  GetAProcAddress(@libvlc_media_list_release , 'libvlc_media_list_release');
  GetAProcAddress(@libvlc_media_list_retain , 'libvlc_media_list_retain');
  GetAProcAddress(@libvlc_media_list_set_media , 'libvlc_media_list_set_media');
  GetAProcAddress(@libvlc_media_list_media , 'libvlc_media_list_media');
  GetAProcAddress(@libvlc_media_list_add_media , 'libvlc_media_list_add_media');
  GetAProcAddress(@libvlc_media_list_insert_media , 'libvlc_media_list_insert_media');
  GetAProcAddress(@libvlc_media_list_remove_index , 'libvlc_media_list_remove_index');
  GetAProcAddress(@libvlc_media_list_count , 'libvlc_media_list_count');
  GetAProcAddress(@libvlc_media_list_item_at_index , 'libvlc_media_list_item_at_index');
  GetAProcAddress(@libvlc_media_list_index_of_item , 'libvlc_media_list_index_of_item');
  GetAProcAddress(@libvlc_media_list_is_readonly , 'libvlc_media_list_is_readonly');
  GetAProcAddress(@libvlc_media_list_lock , 'libvlc_media_list_lock');
  GetAProcAddress(@libvlc_media_list_unlock , 'libvlc_media_list_unlock');
  GetAProcAddress(@libvlc_media_list_event_manager , 'libvlc_media_list_event_manager');

  GetAProcAddress(@libvlc_media_library_new , 'libvlc_media_library_new');
  GetAProcAddress(@libvlc_media_library_release , 'libvlc_media_library_release');
  GetAProcAddress(@libvlc_media_library_retain , 'libvlc_media_library_retain');
  GetAProcAddress(@libvlc_media_library_load , 'libvlc_media_library_load');
  GetAProcAddress(@libvlc_media_library_media_list , 'libvlc_media_library_media_list');

  GetAProcAddress(@libvlc_media_player_new , 'libvlc_media_player_new');
  GetAProcAddress(@libvlc_media_player_new_from_media , 'libvlc_media_player_new_from_media');
  GetAProcAddress(@libvlc_media_player_release , 'libvlc_media_player_release');
  GetAProcAddress(@libvlc_media_player_retain , 'libvlc_media_player_retain');
  GetAProcAddress(@libvlc_media_player_set_media , 'libvlc_media_player_set_media');
  GetAProcAddress(@libvlc_media_player_get_media , 'libvlc_media_player_get_media');
  GetAProcAddress(@libvlc_media_player_event_manager , 'libvlc_media_player_event_manager');
  GetAProcAddress(@libvlc_media_player_is_playing , 'libvlc_media_player_is_playing');
  GetAProcAddress(@libvlc_media_player_play , 'libvlc_media_player_play');
  GetAProcAddress(@libvlc_media_player_pause , 'libvlc_media_player_pause');
  GetAProcAddress(@libvlc_media_player_stop , 'libvlc_media_player_stop');
  GetAProcAddress(@libvlc_media_player_set_nsobject , 'libvlc_media_player_set_nsobject');
  GetAProcAddress(@libvlc_media_player_get_nsobject , 'libvlc_media_player_get_nsobject');
  GetAProcAddress(@libvlc_media_player_set_agl , 'libvlc_media_player_set_agl');
  GetAProcAddress(@libvlc_media_player_get_agl , 'libvlc_media_player_get_agl');
  GetAProcAddress(@libvlc_media_player_set_xwindow , 'libvlc_media_player_set_xwindow');
  GetAProcAddress(@libvlc_media_player_get_xwindow , 'libvlc_media_player_get_xwindow');
  GetAProcAddress(@libvlc_media_player_set_hwnd , 'libvlc_media_player_set_hwnd');
  GetAProcAddress(@libvlc_media_player_get_hwnd , 'libvlc_media_player_get_hwnd');
  GetAProcAddress(@libvlc_media_player_get_length , 'libvlc_media_player_get_length');
  GetAProcAddress(@libvlc_media_player_get_time , 'libvlc_media_player_get_time');
  GetAProcAddress(@libvlc_media_player_set_time , 'libvlc_media_player_set_time');
  GetAProcAddress(@libvlc_media_player_get_position , 'libvlc_media_player_get_position');
  GetAProcAddress(@libvlc_media_player_set_position , 'libvlc_media_player_set_position');
  GetAProcAddress(@libvlc_media_player_set_chapter , 'libvlc_media_player_set_chapter');
  GetAProcAddress(@libvlc_media_player_get_chapter , 'libvlc_media_player_get_chapter');
  GetAProcAddress(@libvlc_media_player_get_chapter_count , 'libvlc_media_player_get_chapter_count');
  GetAProcAddress(@libvlc_media_player_will_play , 'libvlc_media_player_will_play');
  GetAProcAddress(@libvlc_media_player_get_chapter_count_for_title , 'libvlc_media_player_get_chapter_count_for_title');
  GetAProcAddress(@libvlc_media_player_set_title , 'libvlc_media_player_set_title');
  GetAProcAddress(@libvlc_media_player_get_title , 'libvlc_media_player_get_title');
  GetAProcAddress(@libvlc_media_player_get_title_count , 'libvlc_media_player_get_title_count');
  GetAProcAddress(@libvlc_media_player_previous_chapter , 'libvlc_media_player_previous_chapter');
  GetAProcAddress(@libvlc_media_player_next_chapter , 'libvlc_media_player_next_chapter');
  GetAProcAddress(@libvlc_media_player_get_rate , 'libvlc_media_player_get_rate');
  GetAProcAddress(@libvlc_media_player_set_rate , 'libvlc_media_player_set_rate');
  GetAProcAddress(@libvlc_media_player_get_state , 'libvlc_media_player_get_state');
  GetAProcAddress(@libvlc_media_player_get_fps , 'libvlc_media_player_get_fps');
  GetAProcAddress(@libvlc_media_player_has_vout , 'libvlc_media_player_has_vout');
  GetAProcAddress(@libvlc_media_player_is_seekable , 'libvlc_media_player_is_seekable');
  GetAProcAddress(@libvlc_media_player_can_pause , 'libvlc_media_player_can_pause');
  GetAProcAddress(@libvlc_track_description_release , 'libvlc_track_description_release');
  GetAProcAddress(@libvlc_toggle_fullscreen , 'libvlc_toggle_fullscreen');
  GetAProcAddress(@libvlc_set_fullscreen , 'libvlc_set_fullscreen');
  GetAProcAddress(@libvlc_get_fullscreen , 'libvlc_get_fullscreen');
  GetAProcAddress(@libvlc_video_set_deinterlace , 'libvlc_video_set_deinterlace');

  GetAProcAddress(@libvlc_video_get_marquee_int, 'libvlc_video_get_marquee_int');
  GetAProcAddress(@libvlc_video_get_marquee_string, 'libvlc_video_get_marquee_string');
  GetAProcAddress(@libvlc_video_set_marquee_int, 'libvlc_video_set_marquee_int');
  GetAProcAddress(@libvlc_video_set_marquee_string, 'libvlc_video_set_marquee_string');
  GetAProcAddress(@libvlc_video_get_logo_int, 'libvlc_video_get_logo_int');
  GetAProcAddress(@libvlc_video_set_logo_int, 'libvlc_video_set_logo_int');
  GetAProcAddress(@libvlc_video_set_logo_string, 'libvlc_video_set_logo_string');
  GetAProcAddress(@libvlc_video_get_adjust_int, 'libvlc_video_get_adjust_int');
  GetAProcAddress(@libvlc_video_set_adjust_int, 'libvlc_video_set_adjust_int');
  GetAProcAddress(@libvlc_video_get_adjust_float, 'libvlc_video_get_adjust_float');
  GetAProcAddress(@libvlc_video_set_adjust_float, 'libvlc_video_set_adjust_float');

  GetAProcAddress(@libvlc_video_set_key_input , 'libvlc_video_set_key_input');
  GetAProcAddress(@libvlc_video_set_mouse_input , 'libvlc_video_set_mouse_input');
  GetAProcAddress(@libvlc_video_get_size , 'libvlc_video_get_size');
  GetAProcAddress(@libvlc_video_get_cursor , 'libvlc_video_get_cursor');
  GetAProcAddress(@libvlc_video_get_height , 'libvlc_video_get_height');
  GetAProcAddress(@libvlc_video_get_width , 'libvlc_video_get_width');
  GetAProcAddress(@libvlc_video_get_scale , 'libvlc_video_get_scale');
  GetAProcAddress(@libvlc_video_set_scale , 'libvlc_video_set_scale');
  GetAProcAddress(@libvlc_video_get_aspect_ratio , 'libvlc_video_get_aspect_ratio');
  GetAProcAddress(@libvlc_video_set_aspect_ratio , 'libvlc_video_set_aspect_ratio');
  GetAProcAddress(@libvlc_video_get_spu , 'libvlc_video_get_spu');
  GetAProcAddress(@libvlc_video_get_spu_count , 'libvlc_video_get_spu_count');
  GetAProcAddress(@libvlc_video_get_spu_description , 'libvlc_video_get_spu_description');
  GetAProcAddress(@libvlc_video_set_spu , 'libvlc_video_set_spu');
  GetAProcAddress(@libvlc_video_set_subtitle_file , 'libvlc_video_set_subtitle_file');
  GetAProcAddress(@libvlc_video_get_title_description , 'libvlc_video_get_title_description');
  GetAProcAddress(@libvlc_video_get_chapter_description , 'libvlc_video_get_chapter_description');
  GetAProcAddress(@libvlc_video_get_crop_geometry , 'libvlc_video_get_crop_geometry');
  GetAProcAddress(@libvlc_video_set_crop_geometry , 'libvlc_video_set_crop_geometry');
  GetAProcAddress(@libvlc_toggle_teletext , 'libvlc_toggle_teletext');
  GetAProcAddress(@libvlc_video_get_teletext , 'libvlc_video_get_teletext');
  GetAProcAddress(@libvlc_video_set_teletext , 'libvlc_video_set_teletext');
  GetAProcAddress(@libvlc_video_get_track_count , 'libvlc_video_get_track_count');
  GetAProcAddress(@libvlc_video_get_track_description , 'libvlc_video_get_track_description');
  GetAProcAddress(@libvlc_video_get_track , 'libvlc_video_get_track');
  GetAProcAddress(@libvlc_video_set_track , 'libvlc_video_set_track');
  GetAProcAddress(@libvlc_video_take_snapshot , 'libvlc_video_take_snapshot');
  GetAProcAddress(@libvlc_audio_output_list_get , 'libvlc_audio_output_list_get');
  GetAProcAddress(@libvlc_audio_output_list_release , 'libvlc_audio_output_list_release');
  GetAProcAddress(@libvlc_audio_output_set , 'libvlc_audio_output_set');
  GetAProcAddress(@libvlc_audio_output_device_count , 'libvlc_audio_output_device_count');
  GetAProcAddress(@libvlc_audio_output_device_longname , 'libvlc_audio_output_device_longname');
  GetAProcAddress(@libvlc_audio_output_device_id , 'libvlc_audio_output_device_id');
  GetAProcAddress(@libvlc_audio_output_device_set , 'libvlc_audio_output_device_set');
  GetAProcAddress(@libvlc_audio_output_get_device_type , 'libvlc_audio_output_get_device_type');
  GetAProcAddress(@libvlc_audio_output_set_device_type , 'libvlc_audio_output_set_device_type');
  GetAProcAddress(@libvlc_audio_toggle_mute , 'libvlc_audio_toggle_mute');
  GetAProcAddress(@libvlc_audio_get_mute , 'libvlc_audio_get_mute');
  GetAProcAddress(@libvlc_audio_set_mute , 'libvlc_audio_set_mute');
  GetAProcAddress(@libvlc_audio_get_volume , 'libvlc_audio_get_volume');
  GetAProcAddress(@libvlc_audio_set_volume , 'libvlc_audio_set_volume');
  GetAProcAddress(@libvlc_audio_get_track_count , 'libvlc_audio_get_track_count');
  GetAProcAddress(@libvlc_audio_get_track_description , 'libvlc_audio_get_track_description');
  GetAProcAddress(@libvlc_audio_get_track , 'libvlc_audio_get_track');
  GetAProcAddress(@libvlc_audio_set_track , 'libvlc_audio_set_track');
  GetAProcAddress(@libvlc_audio_get_channel , 'libvlc_audio_get_channel');
  GetAProcAddress(@libvlc_audio_set_channel , 'libvlc_audio_set_channel');

  GetAProcAddress(@libvlc_media_list_player_new , 'libvlc_media_list_player_new');
  GetAProcAddress(@libvlc_media_list_player_release , 'libvlc_media_list_player_release');
  GetAProcAddress(@libvlc_media_list_player_set_media_player , 'libvlc_media_list_player_set_media_player');
  GetAProcAddress(@libvlc_media_list_player_set_media_list , 'libvlc_media_list_player_set_media_list');
  GetAProcAddress(@libvlc_media_list_player_play , 'libvlc_media_list_player_play');
  GetAProcAddress(@libvlc_media_list_player_pause , 'libvlc_media_list_player_pause');
  GetAProcAddress(@libvlc_media_list_player_is_playing , 'libvlc_media_list_player_is_playing');
  GetAProcAddress(@libvlc_media_list_player_get_state , 'libvlc_media_list_player_get_state');
  GetAProcAddress(@libvlc_media_list_player_play_item_at_index , 'libvlc_media_list_player_play_item_at_index');
  GetAProcAddress(@libvlc_media_list_player_play_item , 'libvlc_media_list_player_play_item');
  GetAProcAddress(@libvlc_media_list_player_stop , 'libvlc_media_list_player_stop');
  GetAProcAddress(@libvlc_media_list_player_next , 'libvlc_media_list_player_next');

  GetAProcAddress(@libvlc_media_discoverer_new_from_name , 'libvlc_media_discoverer_new_from_name');
  GetAProcAddress(@libvlc_media_discoverer_release , 'libvlc_media_discoverer_release');
  GetAProcAddress(@libvlc_media_discoverer_localized_name , 'libvlc_media_discoverer_localized_name');
  GetAProcAddress(@libvlc_media_discoverer_media_list , 'libvlc_media_discoverer_media_list');
  GetAProcAddress(@libvlc_media_discoverer_event_manager , 'libvlc_media_discoverer_event_manager');
  GetAProcAddress(@libvlc_media_discoverer_is_running , 'libvlc_media_discoverer_is_running');

  GetAProcAddress(@libvlc_vlm_release , 'libvlc_vlm_release');
  GetAProcAddress(@libvlc_vlm_add_broadcast , 'libvlc_vlm_add_broadcast');
  GetAProcAddress(@libvlc_vlm_add_vod , 'libvlc_vlm_add_vod');
  GetAProcAddress(@libvlc_vlm_del_media , 'libvlc_vlm_del_media');
  GetAProcAddress(@libvlc_vlm_set_enabled , 'libvlc_vlm_set_enabled');
  GetAProcAddress(@libvlc_vlm_set_output , 'libvlc_vlm_set_output');
  GetAProcAddress(@libvlc_vlm_set_input , 'libvlc_vlm_set_input');
  GetAProcAddress(@libvlc_vlm_add_input , 'libvlc_vlm_add_input');
  GetAProcAddress(@libvlc_vlm_set_loop , 'libvlc_vlm_set_loop');
  GetAProcAddress(@libvlc_vlm_set_mux , 'libvlc_vlm_set_mux');
  GetAProcAddress(@libvlc_vlm_change_media , 'libvlc_vlm_change_media');
  GetAProcAddress(@libvlc_vlm_play_media , 'libvlc_vlm_play_media');
  GetAProcAddress(@libvlc_vlm_stop_media , 'libvlc_vlm_stop_media');
  GetAProcAddress(@libvlc_vlm_pause_media , 'libvlc_vlm_pause_media');
  GetAProcAddress(@libvlc_vlm_seek_media , 'libvlc_vlm_seek_media');
  GetAProcAddress(@libvlc_vlm_show_media , 'libvlc_vlm_show_media');
  GetAProcAddress(@libvlc_vlm_get_media_instance_position , 'libvlc_vlm_get_media_instance_position');
  GetAProcAddress(@libvlc_vlm_get_media_instance_time , 'libvlc_vlm_get_media_instance_time');
  GetAProcAddress(@libvlc_vlm_get_media_instance_length , 'libvlc_vlm_get_media_instance_length');
  GetAProcAddress(@libvlc_vlm_get_media_instance_rate , 'libvlc_vlm_get_media_instance_rate');
//  GetAProcAddress(@libvlc_vlm_get_media_instance_title , 'libvlc_vlm_get_media_instance_title');
//  GetAProcAddress(@libvlc_vlm_get_media_instance_chapter , 'libvlc_vlm_get_media_instance_chapter');
//  GetAProcAddress(@libvlc_vlm_get_media_instance_seekable , 'libvlc_vlm_get_media_instance_seekable');

  if FLastError = -1 then begin
     raise Exception.Create('libvlc function error!');
  end
  else begin
    // set internal version only, e.g. 1.1.0
    FVersion := Copy(VLC_GetVersion(), 1, 5);
  end;
end;

procedure TLibVLC.VLC_Pause;
// pause media_player
begin
  if Assigned(FPlayer) then
    libvlc_media_player_pause(FPlayer);
end;

procedure TLibVLC.VLC_Play;
// play media_player
begin
  if not Assigned(FPlayer) then
    exit;

  libvlc_media_player_play(FPlayer);
end;

procedure TLibVLC.VLC_Stop;
// stop media_player
var
  i : Integer;
begin
  if not Assigned(FPlayer) then
    exit;

  libvlc_media_player_stop(FPlayer); //-> VLC Stop Problem

  // wait until stop is really finished, because VLC_IsPlaying()
  // will return true during stopping
  for i:=0 to 10 do begin
    if not VLC_IsPlaying() then
      break
    else
      Sleep(100);
  end;
end;

procedure TLibVLC.VLC_ToggleFullscreen(Panel: TPanel; Background: TPanel);
// toggle fullscreen with panel
begin
  if not Assigned(FPnlOutput) then
    exit;

  if Assigned(Background) then begin
    if FBackground.Parent = FFormFS then
      Background.Parent := FBackgroundParent
    else begin
      FBackgroundParent := Background.Parent;
      FBackground := Background;
      FBackground.Parent := FFormFS;
    end;
  end;  

  if FFullscreen then begin
    FFormFS.Close;
    
    SetWindowPos(FFormFS.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
    Application.ProcessMessages;
    
    SetAParent(Panel.Handle, Panel.Parent.Handle, TForm(Panel.Parent).Monitor.Height, TForm(Panel.Parent).Monitor.Width);

    Panel.Top := FOldPanTop;
    Panel.Left := FOldPanLeft;
    Panel.Height := FOldPanHeight;
    Panel.Width := FOldPanWidth;

    FFullscreen := false;
  end
  else begin
    FOldPanTop := Panel.Top;
    FOldPanLeft := Panel.Left;
    FOldPanHeight := Panel.Height;
    FOldPanWidth := Panel.Width;

    SetAParent(Panel.Handle, FFormFS.Handle, TForm(Panel.Parent).Monitor.Height, TForm(Panel.Parent).Monitor.Width);

    Panel.Top := 0;
    Panel.Left := 0;
    Panel.Height := TForm(Panel.Parent).Monitor.Height;
    Panel.Width := TForm(Panel.Parent).Monitor.Width;

    FFormFS.Top := 0;
    FFormFS.Left := 0;
    FFormFS.Height := TForm(Panel.Parent).Monitor.Height;
    FFormFS.Width := TForm(Panel.Parent).Monitor.Width;
    FFormFS.Show;

    SetWindowPos(FFormFS.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
    Application.ProcessMessages;

    SetAParent(Panel.Handle, FFormFS.Handle, TForm(Panel.Parent).Monitor.Height, TForm(Panel.Parent).Monitor.Width);

    FFormFS.SetFocus;

    FFullscreen := true;
  end;
end;

function TLibVLC.GetAProcAddress(var Addr: Pointer; Name: PChar): Integer;
// get function pointer to a dll function
begin
  Addr := GetProcAddress(FDLLHandle, Name);

  if (Addr <> nil) then
    Result := 0
  else begin
    raise Exception.Create(Name);
    
    FLastError := -1;
  end;
end;

function TLibVLC.VLC_GetStats: libvlc_media_stats_t;
// get media stats like "lostbuffers"
begin
  if not Assigned(FPlayer) then
    exit;

  if Assigned(FMedia) and (libvlc_media_player_is_playing(FPlayer) = 1) then
    libvlc_media_get_stats(FMedia, @FStats);

  Result := FStats;
end;

function TLibVLC.SetAParent(hWndChild, hWndNewParent: HWND; NewParentWidth, NewParentHeight: integer): boolean;
// change parent window
var
  hWndPrevParent: HWND;
begin
  hWndPrevParent := Windows.SetParent(hWndChild, hWndNewParent);

  if hWndPrevParent = 0 then
    Result := false
  else
    Result := true;
end;

procedure TLibVLC.VLC_SetChannel(Channel: Integer);
begin
  libvlc_audio_set_channel(FPlayer, Channel);
end;

function TLibVLC.VLC_GetChannel: Integer;
begin
  Result := libvlc_audio_get_channel(FPlayer);
end;

procedure TLibVLC.VLC_SetAudioTrack(iTrack: Integer);
// set audio track
begin
  if not Assigned(FPlayer) then
    exit;

  libvlc_audio_set_track(FPlayer, iTrack);
end;

function TLibVLC.VLC_GetAudioTrack: Integer;
// get current audio track
begin
  Result := -1;

  if not Assigned(FPlayer) then
    exit;

  Result := libvlc_audio_get_track(FPlayer);
end;

procedure TLibVLC.VLC_TakeSnapshot(Path: String; width, height : Integer);
// take a snapshot
begin
  if not Assigned(FPlayer) then
    exit;

  if not Assigned(FPnlOutput) then
    exit;

  libvlc_video_take_snapshot(FPlayer, 0, PAnsiChar(Path), width, height);
end;

procedure TLibVLC.VLC_SetDeinterlaceMode(Mode: String);
// set video deinterlace mode
var
  MyMode : PChar;
begin
  if not Assigned(FPlayer) then
    exit;

  if not Assigned(FPnlOutput) then
    exit;

   MyMode := StrAlloc(length(Mode) + 1);
   StrPCopy(MyMode, Mode);

   libvlc_video_set_deinterlace(FPlayer, MyMode);

   StrDispose(MyMode);
end;

function TLibVLC.VLC_IsPlaying: Boolean;
// get media_player playing status
begin
  Result := false;

  if not Assigned(FPlayer) then
    exit;

  if (libvlc_media_player_is_playing(FPlayer) = 1) then begin
    Result := true
  end  
  else begin
    Result := false;
  end;
end;

procedure TLibVLC.VLC_SetCropMode(Mode: String);
// set video crop mode
begin
  if not Assigned(FPlayer) then
    exit;

  if (Mode = 'default') then
    libvlc_video_set_crop_geometry(FPlayer, PAnsiChar(''))
  else
    libvlc_video_set_crop_geometry(FPlayer, PAnsiChar(Mode));
end;

function TLibVLC.VLC_GetCropMode() : String;
// get video crop mode
begin
  if not Assigned(FPlayer) then
    exit;

  Result := libvlc_video_get_crop_geometry(FPlayer);
end;


procedure TLibVLC.VLC_SetARMode(Mode: String);
// set video aspect ratio
begin
  if not Assigned(FPlayer) then
    exit;

  if (Mode = 'default') then
    libvlc_video_set_aspect_ratio(FPlayer, PAnsiChar(''))
  else
    libvlc_video_set_aspect_ratio(FPlayer, PAnsiChar(Mode));
end;

function TLibVLC.VLC_GetARMode() : String;
// get video aspect ratio
begin
  if not Assigned(FPlayer) then
    exit;

  Result := libvlc_video_get_aspect_ratio(FPlayer);
end;

procedure TLibVLC.VLC_SetMute(Activate : Boolean);
// set mute on/off
begin
  if not Assigned(FPlayer) then
    exit;

  if not Activate then
    libvlc_audio_set_mute(FPlayer, 0)
  else
    libvlc_audio_set_mute(FPlayer, 1);
end;

procedure TLibVLC.VLC_SetVolume (Level : Integer);
// set volume
begin
  if not Assigned(FPlayer) then
    exit;

  libvlc_audio_set_volume(FPlayer, Level);
end;

constructor TLibVLC.Create(InstName, DLL: String; Params: array of PAnsiChar; ParamsCount: Integer; LogLevel: Integer; PnlOutput: TPanel; Callback, Userdata : Pointer);
// load libvlc.dll, init libvlc and init class, with video output!
begin
  if (DLL = '') or (DLL = 'libvlc.dll') then
    DLL := VLC_GetLibPath+'libvlc.dll';
    
  // load libvlccore.dll (well, only needed if vlc is in a diffrent folder then the application)
  FDllHandle := LoadLibrary(PChar(ExtractFilePath(DLL)+'libvlccore.dll'));

  // load libvlc.dll
  FDllHandle := LoadLibrary(PChar(DLL));

  // name
  FName := InstName;

  // fullscreen
  FFullscreen := false;

  if Assigned(PnlOutput) then begin
    FFormFS := TFormFS.CreateNew(nil);

    FFormFS.BorderStyle := bsNone;
    FFormFS.Width := Screen.Width;
    FFormFS.Height := Screen.Height;
    FFormFS.Visible := false;
    FFormFS.Top := 0;
    FFormFS.Left := 0;

    FBackground  := TPanel.Create(FFormFS);

    //output
    FPnlOutput := PnlOutput;
  end;  

  // callback
  FCallback := Callback;

  // callback userdata
  FUserdata := Userdata;

  // check handle
  if FDllHandle = 0 then
     raise Exception.Create('load library failed!');

  // load all dll function pointers
  LoadFunctions;

  // init libvlc instance
  FLib := libvlc_new(ParamsCount, @Params[0]);

  // init logging
  libvlc_set_log_verbosity(FLib, LogLevel);
  FLog := libvlc_log_open(FLib);
  FLogTimer := TTimer.Create(nil);
  FLogTimer.OnTimer := OnLogTimer;
  FLogTimer.Interval := 100;
  FLogTimer.Enabled := true;
end;

function TLibVLC.VLC_GetVersion: String;
// get version
begin
  Result := libvlc_get_version();
end;

function TLibVLC.VLC_GetVolume: Integer;
// get volume
begin
  Result := -1;

  if not Assigned(FPlayer) then
    exit;

  Result := libvlc_audio_get_volume(FPlayer);
end;

function TLibVLC.VLC_GetLibPath: String;
// get vlc library path
var
  Handle:HKEY;
  RegType:integer;
  DataSize:integer;
begin

  Result := '';

  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE,'Software\VideoLAN\VLC',0,KEY_ALL_ACCESS,Handle)=ERROR_SUCCESS) then begin

    if RegQueryValueEx(Handle,'InstallDir',nil,@RegType,nil,@DataSize)=ERROR_SUCCESS then begin
      SetLength(Result,Datasize div 2);
      RegQueryValueEx(Handle,'InstallDir',nil,@RegType,PByte(@Result[1]),@DataSize);
      Result[DataSize div 2]:='\';
    end;

    RegCloseKey(Handle);
  end;

end;

procedure TLibVLC.VLC_PlayMedia(MediaURL: String; MediaOptions: TStringList; Panel : TPanel);
// create new player and new media
var
  i : Integer;
  Pevent_manager : Plibvlc_event_manager_t;
  Option : AnsiString;
begin
  // media
  FMediaURL := MediaURL;
  FMediaOpt := MediaOptions;

  if not Assigned(FMedia) then begin
    if FileExists(Trim(FMediaURL)) then
      FMedia := libvlc_media_new_path(FLib, PAnsiChar(AnsiString(Trim(FMediaURL))))
    else
      FMedia := libvlc_media_new_location(FLib, PAnsiChar(AnsiString(Trim(FMediaURL))));
  end;

  for i := 0 to FMediaOpt.Count-1 do begin
    Option := Utf8Encode(FMediaOpt.Strings[i]);
    libvlc_media_add_option(FMedia, PAnsiChar(Option));
  end;

  if not Assigned(FPlayer) then
    FPlayer := libvlc_media_player_new_from_media(FMedia);

//  libvlc_media_release(FMedia); // could be released, but needed for VLC_GetStats()

  if Assigned(FPnlOutput) then begin
    if Assigned(Panel) then
      libvlc_media_player_set_hwnd(FPlayer, Pointer(Panel.Handle))
    else
      libvlc_media_player_set_hwnd(FPlayer, Pointer(FPnlOutput.Handle));
  end;

//  libvlc_video_set_mouse_input(FPlayer, 0); // mouse still always hidden...
//  libvlc_video_set_key_input(FPlayer, 1);

  // register all events 
  if Assigned(FCallback) then begin
    Pevent_manager := libvlc_media_player_event_manager(FPlayer);

    for i:=0 to sizeof(libvlc_events)-1 do begin
      libvlc_event_attach(Pevent_manager,
                        libvlc_events[i],
                        FCallback,
                        FUserdata);
    end;
  end;

  libvlc_media_player_play(FPlayer);
end;

procedure TLibVLC.VLC_StopMedia;
// stop media_player and free player + media
var
  i : Integer;
begin
  if Assigned(FPlayer) then begin
    libvlc_media_player_stop(FPlayer); //-> VLC Stop Problem

    // wait until stop is really finished
    for i:=0 to 10 do begin
      if not VLC_IsPlaying() then
        break
      else
        Sleep(100);
    end;

    libvlc_media_player_release(FPlayer);// -> VLC Stop Problem
    FPlayer := nil;
  end;

  if Assigned(FMedia) then begin
    libvlc_media_release(FMedia);//-> VLC Stop Problem
    FMedia := nil;
  end;
end;

procedure TLibVLC.VLC_AdjustVideo (Contrast: Double; Brightness : Double; Hue : Integer; Saturation : Double; Gamma : Double);
// adjust video output
begin
  if Assigned(FPlayer) then begin
    libvlc_video_set_adjust_int(FPlayer, libvlc_adjust_Enable, 1);

    libvlc_video_set_adjust_float(FPlayer, libvlc_adjust_Contrast, Contrast);
    libvlc_video_set_adjust_float(FPlayer, libvlc_adjust_Brightness, Brightness);
    libvlc_video_set_adjust_float(FPlayer, libvlc_adjust_Hue, Hue);
    libvlc_video_set_adjust_float(FPlayer, libvlc_adjust_Saturation, Saturation);
    libvlc_video_set_adjust_float(FPlayer, libvlc_adjust_Gamma, Gamma);
  end;
end;

procedure TLibVLC.VLC_ResetVideo;
// reset video output to default
begin
  if Assigned(FPlayer) then begin
    libvlc_video_set_adjust_int(FPlayer, libvlc_adjust_Enable, 0);
  end;
end;

procedure TLibVLC.VLC_SetLogo(LogoFile: string);
begin
   libvlc_video_set_logo_string(FPlayer,libvlc_logo_file,PAnsiChar(AnsiString(LogoFile)));
   libvlc_video_set_logo_int(FPlayer,libvlc_logo_x,0);
   libvlc_video_set_logo_int(FPlayer,libvlc_logo_y,0);
   libvlc_video_set_logo_int(FPlayer,libvlc_logo_repeat,-1); // continuous?
   libvlc_video_set_logo_int(FPlayer,libvlc_logo_opacity,255); // totally opaque
   libvlc_video_set_logo_int(FPlayer,libvlc_logo_enable, 1);
end;

procedure TLibVLC.VLC_ToggleFullscreen(Frame: TFrame; Background: TPanel);
// toggle fullscreen with panel in a frame
begin

  if not Assigned(FPnlOutput) then
    exit;

  if Assigned(Background) then begin
    if FBackground.Parent = FFormFS then
      Background.Parent := FBackgroundParent
    else begin
      FBackgroundParent := Background.Parent;
      FBackground := Background;
      FBackground.Parent := FFormFS;
    end;
  end;  

  if FFullscreen then begin
    FFormFS.Hide;

    SetWindowPos(FFormFS.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

    SetAParent(Frame.Handle, Frame.Parent.Handle, TForm(Frame.Parent).Monitor.Height, TForm(Frame.Parent).Monitor.Width);

    Frame.Top := FOldPanTop;
    Frame.Left := FOldPanLeft;
    Frame.Height := FOldPanHeight;
    Frame.Width := FOldPanWidth;

    FFullscreen := false;
  end
  else begin
    FOldPanTop := Frame.Top;
    FOldPanLeft := Frame.Left;
    FOldPanHeight := Frame.Height;
    FOldPanWidth := Frame.Width;

    SetAParent(Frame.Handle, FFormFS.Handle, TForm(Frame.Parent).Monitor.Height, TForm(Frame.Parent).Monitor.Width);

    Frame.Top := 0;
    Frame.Left := 0;
    Frame.Height := TForm(Frame.Parent).Monitor.Height;
    Frame.Width := TForm(Frame.Parent).Monitor.Width;

    FFormFS.Top := 0;
    FFormFS.Left := 0;
    FFormFS.Height := TForm(Frame.Parent).Monitor.Height;
    FFormFS.Width := TForm(Frame.Parent).Monitor.Width;
    FFormFS.Show;

    SetWindowPos(FFormFS.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

    FFormFS.SetFocus;

    FFullscreen := true;
  end;
end;

function TLibVLC.VLC_GetAudioTrackList: String;
// get audio tracklist from current playback
var
  Track : Plibvlc_track_description_t;
begin
  Result := '';

  if not Assigned(FPlayer) then
    exit;

  // first track is only for deactivating sound...
  Track := libvlc_audio_get_track_description(FPlayer);
  if not Assigned(Track) then
    exit;

  // so we take the second one...
  Track := Track.p_next;
  if not Assigned(Track) then
    exit;

  // and all others following...
  repeat
    Result := Result + IntToStr(Track.i_id)+' '+Track.psz_name+ChrCRLF;
    Track := Track.p_next;
  until not Assigned(Track);

end;

procedure TLibVLC.VLC_SetMarquee(Text: String; Color, Opac, Pos, Refresh, Size, Timeout, X, Y: Integer);
// set marquee text
begin
  // options
  libvlc_video_set_marquee_string(FPlayer, libvlc_marquee_Text, PAnsiChar(AnsiString(Text)));
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Color, Color);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Opacity, Opac);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Position, Pos);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Refresh, Refresh);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Size, Size);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Timeout, Timeout);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_X, X);
  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Y, Y);

  libvlc_video_set_marquee_int(FPlayer, libvlc_marquee_Enabled, 1);
end;

function TLibVLC.VLC_GetMute: Boolean;
// read mute status
begin
  Result := false;

  if not Assigned(FPlayer) then
    exit;

  if libvlc_audio_get_mute(FPlayer) = 1 then
    Result := true;
end;

procedure TLibVLC.OnLogTimer(Sender: TObject);
// timer log event
var
  AIterator: Plibvlc_log_iterator_t;
  AMessage: libvlc_log_message_t;
begin
  if not Assigned(FLog) then
    exit;

  if (libvlc_log_count(FLog) > 0) then begin
    AIterator := libvlc_log_get_iterator(FLog);

    if Assigned(FLogEvent) then begin
      while (libvlc_log_iterator_has_next(AIterator) > 0) do begin
        libvlc_log_iterator_next(AIterator, @AMessage);
        FLogEvent(AMessage);
      end;
    end;

    libvlc_log_clear(FLog);
  end;
end;

function TLibVLC.VLC_GetEventString(event: libvlc_event_t): String;
// returns a event-string for a libvlc_event_t
var
  i : Integer;
begin
  for i:=0 to sizeof(libvlc_events)-1 do begin
    if event._type = libvlc_events[i] then begin
      Result := libvlc_events_text[i];
      break;
    end;
  end;
end;

{ TFormFS }

procedure TFormFS.CreateParams(var Params: TCreateParams);
// -create a form with stayontop and desktop as parent, so no other window can disturb
// -toolwindow to prevent taskbar entry
begin
  inherited CreateParams(Params);
  with Params do begin
    ExStyle := ExStyle or WS_EX_TOPMOST or WS_EX_TOOLWINDOW;
    WndParent := GetDesktopwindow;
  end;
end;

initialization

end.
