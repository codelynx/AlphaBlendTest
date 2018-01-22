BlendFuncTest
=============

I was working on some experimental code using `Metal`, and I have some problem of blending issue with `Metal`, and it is pretty pain to repeat try and error over and over again.  Then I found out that Metal's blending does not meet my requirement when I ran into this article.

• [Alpha Blending の2種類の算出方法と使い分け](http://neareal.com/2428/)

According to this article, typical alpha blending for games is as follows:

```
	Cr = Cd * (1 - As) + Cs * As
```

But, blending for paint kind of requires blending function as follows:

```
	Ar = As + (1 - As) * Ad
	Cr = [(Cs * As) + (Cd * (1 - As) * Ad)] / Ar
```

So, I wanted to try if this formula works by computing with CPU. Then here is the code.  You may play with `blend()` function on `ViewController` class to see if you like to try any other interesting blend function. It uses normalized simd `float4` for in and out, so it should be easy to work with.

```.swift
	func blend(source S: float4, destination D: float4) -> float4 {
		let Ra = S.a +  D.a * (1.0 - S.a)
		let Rrgb: float3 = Ra == 0 ? float3(0) : ((S.rgb * S.a) + (D.rgb * D.a * (1.0 - S.a) )) / Ra
		return float4(Rrgb.r, Rrgb.g, Rrgb.b, Ra)
	}
```

Then, just like the screen shot below, you will see the blended image done by `blend()` function.  You may choose source or destination image to see how the blend function work with some other images.  The image shown as labeled `Expected:` is actually composited by two `NSImageView`s that one on top the other.

![Screen Shot 2018-01-22 at 12.22.36 AM.png](https://qiita-image-store.s3.amazonaws.com/0/65634/bdb92413-f626-e9b4-3042-10bc0622264e.png)

As you can see, this blend function worked as I expected, and my alpha blending journey ends here.

## Wikipedia

More detailed description about alpha compositing can be found as follows: 

https://en.wikipedia.org/wiki/Alpha_compositing

## Environment

#### Swift

```
swift --version
Apple Swift version 4.0.3 (swiftlang-900.0.74.1 clang-900.0.39.2)
Target: x86_64-apple-macosx10.9
```

#### Xcode

```
Version 9.2 (9C40b)
```


## License
MIT License
