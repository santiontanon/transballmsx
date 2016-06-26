/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package musicconverter;

/**
 *
 * @author santi
 */
public class Main {
    public static void main(String args[]) throws Exception {
//        MSXSong song = TransballSong.createTransballSong();
//        MSXSong song = TransballSong.createTransballSongWithGotos();
        MSXSong song = TransballSong.createTransballSongWithRepeats();
        
        System.out.println("Channel 0 duration: " + song.channelLength(0));
        System.out.println("Channel 1 duration: " + song.channelLength(1));
        System.out.println("Channel 2 duration: " + song.channelLength(2));
        
//        SongToPSGData.convert(song);
        int l1 = SongToPSGDataV2.convertByChannel(song,"Transball_song_channel1",0, true);
        int l2 = SongToPSGDataV2.convertByChannel(song,"Transball_song_channel2",1, false);
        int l3 = SongToPSGDataV2.convertByChannel(song,"Transball_song_channel3",2, false);
        System.out.println(";; total size: " + (l1+l2+l3));
    }
}
