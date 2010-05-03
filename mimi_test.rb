require './lib/madmimi'

mimi = MadMimi.new('nicholas@nicholaswyoung.com', 'f745b56de62ab9b46f613173a10806fb')

opt = { 'promotion_name' => 'Test Plaintext', 'recipients' => 'nicholas young <nicholas@madmimi.com>', 'from' => 'mad mimi <rubyclass@madmimi.com>',
        'subject' => 'rock and roll!' }

plaintext = 'this is my plaintext [[unsubscribe]]'

mimi.send_plaintext(opt, plaintext)