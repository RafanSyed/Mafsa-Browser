//
//  Keywords.swift
//  Pure Path Browser
//
//  Created by Rafan Syed on 10/2/26.
//

import Foundation

enum Keywords {
    // Paste the same lists you use in the Chrome/Safari extension.
    static let keywords: [String] = [
        "manga", "manhwa", "manhua", "webtoon", "scanlation", "scanlations",
         "scanlator", "read manga", "read manhwa", "read manhua", "read webtoon", "toon", "anime",
         "mangadex", "mangakakalot", "manganato", "mangafreak", "mangahere",
         "mangafox", "mangapanda", "mangastream", "kissmanga", "readmanga",
         "mangareader", "manganelo", "mangapark", "bato.to", "batoto",
         "dynasty-scans", "webtoons.com", "tapas.io", "lezhin", "tappytoon",
         "pocket comics", "raw manga", "raw chapter", "raw scan", "manhwa raw",
         "webtoon raw", "translated manga", "fan translation", "doujin",
         "doujinshi", "doujins", "hentai", "hentai manga", "ecchi", "seinen",
         "josei", "shoujo", "shonen", "bl manga", "yaoi", "yuri", "smut manga",
         "adult manga", "mature manga", "r18 manga", "18+ manga",

         // === EXPLICIT/ADULT TERMS ===
         "porn", "porno", "pornography", "pornographic", "xxx", "xxx videos",
         "adult content", "adult videos", "adult films", "nsfw", "not safe for work",
         "r18", "r-18", "18plus", "18+", "21+", "adults only", "mature content",
         "explicit content", "graphic content",

         // === SEXUAL ACTS ===
         "sex", "sexual", "intercourse", "coitus", "fornication", "anal sex",
         "oral sex", "blowjob", "blow job", "fellatio", "cunnilingus", "handjob",
         "hand job", "footjob", "foot job", "titjob", "tit job", "sixty nine",
         "threesome", "3some", "foursome", "4some", "gangbang", "gang bang",
         "orgy", "orgies", "bukkake", "creampie", "cream pie", "cumshot",
         "cum shot", "money shot", "double penetration", "fisting", "fingering",
         "rimming", "rimjob", "rim job", "anilingus", "pegging", "edging",
         "gooning", "tribbing", "scissoring",

         // === BODY PARTS (EXPLICIT) ===
         "penis", "penises", "cock", "cocks", "dick", "dicks", "schlong", "dong",
         "pecker", "vagina", "vaginas", "pussy", "pussies", "cunt", "vulva",
         "labia", "clit", "clitoris", "asshole", "butthole", "breasts", "boobs",
         "boob", "tits", "tit", "titties", "titty", "knockers", "jugs", "melons",
         "hooters", "nipples", "nipple", "areola", "areolas", "testicles",
         "scrotum", "badonkadonk",

         // === SLANG/VULGAR ===
         "cum", "cumming", "jizz", "ejaculate", "ejaculation", "semen", "sperm",
         "precum", "squirt", "squirting", "gushing", "orgasm", "orgasms",
         "climax", "climaxing", "masturbate", "masturbation", "masturbating",
         "jerk off", "jerking off", "jacking off", "wank", "wanking",
         "horny", "aroused", "erection", "boner", "throbbing", "hot women",
         "hot girls", "hot girl",

         // === FETISH/KINK ===
         "fetish", "fetishes", "kink", "kinky", "bdsm", "bondage", "dominance",
         "submission", "sadism", "masochism", "tied up", "rope play", "shibari",
         "handcuffs", "restraints", "gagged", "blindfolded", "whipping",
         "spanking", "paddling", "caning", "flogging", "riding crop",
         "dildo", "dildos", "vibrator", "vibrators", "sex toy", "sex toys",
         "butt plug", "buttplug", "anal beads", "cock ring", "strap-on",
         "strapon", "fleshlight", "foot worship", "voyeur", "voyeurism",
         "exhibitionism", "public sex", "gloryhole", "swinging", "swingers",
         "cuckold", "cuckolding", "hotwife", "chastity", "breathplay", "choking",

         // === TABOO/ILLEGAL ===
         "incest", "stepmom", "step mom", "stepdad", "step dad", "stepsis",
         "stepsister", "stepbrother", "stepmother", "stepfather", "family sex",
         "daddy kink", "loli", "lolita", "lolicon", "shota", "shotacon",
         "jailbait", "teen sex", "teenage sex", "barely legal", "rape", "raped",
         "non-consent", "date rape", "bestiality", "zoophilia", "animal sex",

         // === SEX WORK ===
         "prostitute", "prostitution", "hooker", "call girl", "escort service",
         "happy ending", "stripper", "strip club", "exotic dancer", "lap dance",
         "brothel", "red light district", "sex worker", "sex work", "onlyfans",
         "only fans", "fansly", "cam girl", "cam boy", "camgirl", "camboy",
         "webcam model", "chaturbate", "myfreecams", "livejasmin", "stripchat",

         // === DATING/HOOKUP ===
         "hookup", "hook up", "one night stand", "casual sex", "booty call",
         "fuck buddy", "fuckbuddy", "friends with benefits", "sugar daddy",
         "sugar baby", "seeking arrangement", "grindr", "sniffies",

         // === SLANG DESCRIPTORS ===
         "slut", "slutty", "whore", "thot", "nympho", "nymphomaniac", "milf",
         "dilf", "fuckboy", "seductress", "temptress",

         // === EROTIC/ROMANTIC ===
         "erotic", "erotica", "sensual", "seductive", "seduction", "sultry",
         "steamy", "lust", "lustful", "taboo", "naughty", "lewd", "obscene",
         "indecent", "raunchy", "salacious", "licentious", "lascivious", "carnal",

         // === CLOTHING (REVEALING) ===
         "nudity", "nudist", "nudes", "nude", "naked", "lingerie", "panties",
         "thong", "g-string", "corset", "bustier", "babydoll", "chemise",
         "negligee", "garter belt", "fishnets", "thong bikini", "micro bikini",
         "string bikini", "monokini", "see through", "seethrough", "see-through",
         "camel toe", "cameltoe", "nip slip", "nipslip", "wardrobe malfunction",
         "upskirt", "downblouse", "bikini try on", "swimsuit try on",
         "lingerie try on", "braless", "no panties", "pokies", "topless",

         // === ACTIONS/POSES ===
         "twerk", "twerking", "pole dance", "striptease", "strip tease",
         "doggy style", "doggystyle", "oiled up", "making out",
         "groping", "fondling",

         // === ART/MEDIA ===
         "nude art", "nude painting", "nude sculpture", "erotic art",
         "boudoir", "boudoir photography", "literotica", "erotic fiction",
         "erotic novel", "smut", "smutty", "omegaverse", "breeding",
         "impregnation", "pregnancy kink",

         // === ADULT PLATFORMS ===
         "nhentai", "hitomi.la", "tsumino", "hentai haven", "hanime",
         "hentaigasm", "simply hentai", "gelbooru", "danbooru", "sankaku",
         "e621", "f95zone", "rule34", "rule 34", "ahegao",
         "leaked nudes", "nude leak", "celebrity nudes", "revenge porn",
         "thirst trap", "thirsttrap",

         // === MISC SEXUAL ===
         "cocksucker", "motherfucker", "fuck", "fucked", "fucking",
         "banging", "screwing", "nailing", "pounding", "smashing", "railing",
         "drilling", "dicking", "dick pic", "dickpic", "send nudes",
         "sexting", "phone sex", "cyber sex", "sex chat", "adult chat",
         "discord nsfw", "reddit gonewild", "r/gonewild", "r/nsfw",
    ]
    static let exceptions: Set<String> = [
         "ass", "hard", "wet", "raw", "grind", "oil", "rub", "lace",
         "silk", "satin", "mesh", "tights", "bra", "abs", "gains",
         "peach", "toned", "ripped", "thick", "curves", "spread",
         "flexible", "split", "splits", "bedroom", "kissing", "touching",
         "sucking", "biting", "licking", "squeeze", "squeezing",
         "art", "artwork", "museum", "gallery", "galleries", "sculpture",
         "sculptures", "statue", "statues", "fine art", "classical art",
         "modern art", "contemporary art", "spicy", "dark romance",
         "forbidden", "savage", "beast", "beastly", "heat", "mating",
         "breeding", "rut", "pov", "amateur", "homemade", "influencer",
         "swimsuit", "bathing suit", "one piece", "sports bra", "crop top",
         "leggings", "yoga pants", "spandex", "bodysuit", "bikini",
         "try on haul", "try-on haul", "clothing haul", "outfit reveal",
         "dress reveal", "shirtless", "backless", "cleavage", "big",
         "fat", "small", "tight", "short", "slave", "sub", "dom",
         "master", "mistress", "collar", "leash", "chain", "cuff",
         "gag", "rubber", "leather", "latex", "pvc", "forced",
         "daddy", "mommy", "submission", "discipline", "dominance",
         "oral", "anal", "dp", "facial", "load", "nut", "rod",
         "shaft", "member", "johnson", "rack", "cheeks", "bum",
         "buns", "rump", "posterior", "backside", "balls", "nuts", "sack",
         "moist", "dripping", "stroke", "stroking", "flick", "flicking",
         "erect", "stiff", "arousal", "desire", "longing", "yearning",
         "temptation", "passionate", "intimate", "intimacy", "sensual",
         "suggestive", "provocative", "titillating", "scandalous", "risque",
         "vulgar", "crude", "indecent", "dirty", "filthy", "naughty",
         "taboo", "forbidden", "carnal", "primal", "raw", "savage",
         "escort", "massage parlor", "private dance", "gentleman", "pimp",
         "discreet", "affair", "cheating", "fling", "player", "stud",
         "stallion", "cougar", "zaddy", "snack", "bombshell", "vixen",
         "curvy", "voluptuous", "busty", "slim", "petite", "toned",
         "shredded", "jacked", "swole", "v-line", "thigh gap", "hip dips",
         "love handles", "muffin top", "dad bod", "mom bod",
         "downward dog", "bridge pose", "on knees", "kneeling", "crawling",
         "on bed", "in bed", "bathtub", "wet body", "oil", "oiled",
         "licking", "biting", "neck kiss", "hickey", "love bite",
         "grabbing", "caressing", "groping", "fondling",
         "romance novel", "adult novel", "booktok", "spicy book",
         "mafia romance", "bully romance", "enemies to lovers",
         "age gap romance", "reverse harem", "why choose",
         "alpha omega", "omegaverse",
         "homemade", "real amateur", "point of view",
         "mirror selfie", "bathroom selfie", "ig model",
         "instagram model", "tiktok", "egirl", "eboy", "uwu",
         "bang", "banging", "banged", "screw", "screwing", "nail",
         "nailing", "pound", "pounding", "smash", "smashing", "rail",
         "railing", "drill", "drilling", "pipe", "piping", "clap", "clapping",
         "hit", "hitting", "kik", "wickr",
    ]
    static let hardBlock: Set<String> = [
          "porn", "porno", "pornography", "pornographic", "hentai", "nsfw",
          "xxx", "18+", "r18", "loli", "lolicon", "shota", "shotacon",
          "onlyfans", "chaturbate", "nhentai", "gelbooru", "danbooru",
          "e621", "f95zone", "rule34", "ahegao", "jailbait", "teen sex",
          "barely legal", "rape", "raped", "non-consent", "bestiality",
          "zoophilia", "leaked nudes", "nude leak", "revenge porn",
          "sex", "sexual", "intercourse", "blowjob", "blow job", "handjob",
          "hand job", "cumshot", "creampie", "gangbang", "threesome",
          "orgy", "masturbate", "masturbation", "ejaculation", "boner",
          "erection", "pussy", "cock", "cocks", "dick", "dicks", "vagina",
          "cunt", "tits", "boobs", "nipples", "nude", "nudity", "nudes",
          "naked", "erotic", "erotica", "horny", "fetish", "bdsm", "bondage",
          "dildo", "vibrator", "butt plug", "sex toy", "sexting",
          "stripper", "strip club", "prostitute", "prostitution",
          "escort service", "sex worker", "sex work", "cam girl", "camgirl",
          "camboy", "manga", "manhwa", "manhua", "webtoon", "hentai manga",
          "doujin", "doujinshi", "scanlation", "chapter", "ecchi", "yaoi",
          "yuri", "anime", "thirst trap", "discord nsfw", "r/gonewild",
          "r/nsfw", "bikini try on", "lingerie try on", "upskirt",
          "downblouse", "nip slip", "camel toe", "topless", "braless",
          "twerking", "striptease", "doggy style", "boudoir",
          "literotica", "erotic fiction", "erotic novel", "smut",
          "adult chat", "sex chat", "phone sex", "cyber sex",
          "dick pic", "send nudes", "fuck", "fucked", "fucking",
          "cocksucker", "motherfucker",
    ]
}
