// Nightmare Library: Kevin Liao
 
// amount of time for chatter
60::second => dur CHATTER_TIME;
// time at which chatter ends
now + CHATTER_TIME => time CHATTER_END;
// quarter note
1::second => dur QUARTER;

// acceleration factor
0.88 => float acc;
// acceleration exponent
1 => int exp;

// array of all file names for chatter
["ambiance.wav", "bell.wav", "cough.wav", 
"fax.wav", "pages.wav", "pencil.wav", 
"printer.wav", "printer2.wav",
"sneeze.wav", "sneeze2.wav", "typing.wav"] @=> string files[];

// Separate panned reverbs, which go to dac
NRev rrev => dac.right;
0.1 => rrev.mix;
NRev lrev => dac.left;
0.1 => lrev.mix;
// mono reverb for unpanned sounds
NRev rev => dac;
0.05 => rev.mix;

// begin piece
spork ~ shush();

while( now < CHATTER_END ) {
    spork ~ yay(exp);
    Math.pow(acc, exp) => float factor;
    // "constrained randomness"
    // duration between each call to play a sound file is shortened
    Math.random2f(4*factor,6*factor)::second => now;
    if (exp < 20) exp++; 
}

// derived from sndbuf.ck ChucK example
fun void yay(int exp) {
    // access random sound file
    "sounds/" + files[Math.random2(0,10)] => string file; 
    me.dir() + "/" + file => string filename;
    SndBuf buf => Pan2 pan;
    pan.pan(Math.random2f(-1,1));
    pan.right => rrev;
    pan.left => lrev; 
    // load the file
    filename => buf.read;
    // change buf gain - "constrained randomness"
    Math.random2f(.25 + exp/30, .50 + exp/30) => buf.gain;
    while( now < CHATTER_END ) {
        10::ms => now;
    }
}

fun void shush() {
    CHATTER_TIME - 400::ms => now;
    me.dir() + "/shush.wav" => string filename;
    if( me.args() ) me.arg(0) => filename;
    SndBuf buf => rev;
    filename => buf.read;
    50000 => buf.pos;
    2 => buf.gain;
    3::second => now;
}

3.5::second => now;

SndBuf buffy;
DelayL delay => LPF lowpass => rev; 
400 => lowpass.freq;
1 => lowpass.Q;

delay => Gain g => delay; 

me.dir() + "/altered sounds/printer copy.wav" => buffy.read;

spork ~ automation();
// Comb filter derived from 7-tune-play.ck
for( 0 => int i; i < 4; i++ )
{
    // play it!
    play( buffy, delay, 1, 23, .8, QUARTER );
    QUARTER => now;
    play( buffy, delay, 1, 25, .8, QUARTER );
    QUARTER => now;
    play( buffy, delay, 1, 26, .8, QUARTER );
    QUARTER => now;    
    play( buffy, delay, 1, 30, .8, QUARTER );
    QUARTER => now;
    // advance time
}
delay =< lowpass;
delay => rev;

for( 0 => int i; i < 2; i++ )
{
    // play it!
    play( buffy, delay, 1, 23, .8, QUARTER );
    spork ~ doot(1);
    QUARTER => now;
    play( buffy, delay, 1, 25, .8, QUARTER );
    spork ~ boot();
    QUARTER => now;
    play( buffy, delay, 1, 26, .8, QUARTER );
    spork ~ doot(0);
    QUARTER => now;    
    play( buffy, delay, 1, 30, .8, QUARTER );
    QUARTER => now;
    // advance time
}

spork ~ fax();

for( 0 => int i; i < 2; i++ )
{
    // play it!
    play( buffy, delay, 1, 23, .92, QUARTER );
    spork ~ doot(1);
    QUARTER => now;
    play( buffy, delay, 1, 25, .92, QUARTER );
    spork ~ boot();
    QUARTER => now;
    play( buffy, delay, 1, 26, .92, QUARTER );
    spork ~ doot(0);
    QUARTER => now;    
    play( buffy, delay, 1, 30, .92, QUARTER );
    QUARTER => now;
    // advance time
}


// Comb filter from Ge Wang 7-tune-play.ck
fun void play( SndBuf buf, DelayL delay, float gain, float pitch, float attenuation, dur T )
{
    // connect
    buf => delay;
    // attenuation
    attenuation => g.gain;
    // freq
    pitch => Std.mtof => float freq;
    // sample rate
    second / samp => float SRATE;
    // delay in samples
    (SRATE / freq)::samp => delay.delay;
    
    // set the playhead
    0 => buf.pos;
    // set the gain
    gain => buf.gain;
    // advance
    T => now;
    // disconnect
    buf =< delay;
}

// automation function adapted from Ge Wang THX deep note code

fun void automation() {
    now => time start;
    while( now < start + 32::QUARTER ) {
        (now - start)/(32::QUARTER) => float progress;
        400 + (16000-400)*progress => lowpass.freq;
        50::ms => now;
    }
    <<< "done" >>>;
}

fun void fax() {
    SndBuf fax;
    .1 => fax.gain;
    me.dir() + "/altered sounds/fax copy.wav" => fax.read;
    fax => PitShift shift => Pan2 pan => dac;
    while( true ) {
        0 => fax.pos;
        1 => shift.mix;
        Math.random2f(.25, 1.5) => shift.shift;
        Math.random2f(-1,1) => pan.pan;
        Math.random2f(50,250)::ms => now;
    }
}

fun void doot(int side) {
    SndBuf fax;
    .5 => fax.gain;
    me.dir() + "/altered sounds/fax copy.wav" => fax.read;
    fax => PitShift shift => Pan2 pan;
    1 => pan.pan;
    if( side ){
        pan.left => lrev;
        pan.right => rrev;
    }
    else{
        pan.left => rrev;
        pan.right => lrev;
    }
    1 => shift.mix;
    for( 0 => int i; i < 4; i++ ) {
        0 => fax.pos;
        2.0 - (i/10.0) => shift.shift;
        QUARTER/8 => now;
        pan.pan() - 0.5 => pan.pan;
        0 => fax.pos;
        QUARTER/8 => now;
        pan.pan() - 0.25 => pan.pan;
    }
}

fun void boot() {
    SndBuf print;
    1.5 => print.gain;
    me.dir() + "/altered sounds/printer copy.wav" => print.read;
    print => rev;
    2.0 => print.rate;
    for( 0 => int i; i < 3; i++ ) {
        1.5 => print.gain;
        0 => print.pos;
        QUARTER * 2 / 9 => now;
        0 => print.gain;
        QUARTER/ 9 => now;
    }
}
10::second => now;


