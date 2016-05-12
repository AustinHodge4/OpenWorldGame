// Alloy Physical Shader Framework
// Copyright 2013-2015 RUST LLC.
// http://www.alloy.rustltd.com/

using System.Linq;
using UnityEngine;

namespace Alloy
{
	public class AlloyPackerCompositor
	{
		private static float GetChannel(Texture2D tex, float val, bool linear, float u, float v, int mipLevel, float rangeX,
		                                float rangeY, int channel) {
			float value = 0.0f;
			bool isAlpha = channel == 3; //TODO: Check format to ensure alpha?

			if (tex == null) {
				value = val;
			} else if (mipLevel == 0) {
				value = tex.GetPixelBilinear (u, v) [channel];
			} else {
				// Averages the result over the area within the 'pixel' for this mip level
				// this is similar, but not quite exactly the same as trilinear filtering.
				for (int x = -mipLevel; x < mipLevel; ++x) {
					for (int y = -mipLevel; y < mipLevel; ++y) {
						float um = u + (x * rangeX);
						float vm = v - (y * rangeY);
						value += tex.GetPixelBilinear (um, vm) [channel];
					}
				}

				int t = mipLevel * 2;
				value /= t * t;
			}

			// Gamma correct here
			// If editor is in linear, texture was not bypassing srgb
			if (linear && !isAlpha) {
				value = Mathf.LinearToGammaSpace(value);
			}

			return value;
		}

		private static Vector4 GetChannels(Texture2D tex, float u, float v, int miplevel, int w, int h, float rangeX, float rangeY) {
			if (tex == null)
				return Vector4.zero;


			if (miplevel == 0) {
				return tex.GetPixelBilinear(u, v);
			}

			// Averages the result over the area within the 'pixel' for this mip level
			// this is similar, but not quite exactly the same as trilinear filtering.
			Vector4 value = Vector4.zero;

			for (int x = -miplevel; x < miplevel; x++) {
				for (int y = -miplevel; y < miplevel; y++) {
					float um = u + (x * rangeX);
					float vm = v - (y * rangeY);

					value += (Vector4) tex.GetPixelBilinear(um, vm);
				}
			}

			int t = miplevel * 2;
			value /= t * t;

			return value;
		}

		public static void CompositeMips(Texture2D target, AlloyCustomImportObject source, 
			Texture2D[] maps,
			bool[] linear,
			Texture2D normalMap, 
			int mipLevel) {
			// Basically a 1:1 port of the original shader
			// The only point of major difference is the filtering method used; which is a fraction simpler.

			// This was disabled, since it appears GetPixels results don't appear to be affected by Unity's messing with Linear inputs; the same way they do at runtime. Re-enable if you like.

			int w = Mathf.Max(1, target.width >> mipLevel);
			int h = Mathf.Max(1, target.height >> mipLevel);

			var colors = new Color[w * h];

			float offX = 0.5f / w; // Half a pixel
			float offY = 0.5f / h;

			float rangeX = (1.0f / (mipLevel + 1)) / w;
			float rangeY = (1.0f / (mipLevel + 1)) / h;


			foreach (var channel in source.PackMode.Channels) {
				var inIndices = channel.InputIndices.ToArray();
				var outIndices = channel.OutputIndices.ToArray();

				for (int x = 0; x < w; x++) {
					for (int y = 0; y < h; y++) {
						float u = (float)x / w + offX;
						float v = (float)y / h + offY;

						Color col = colors[y * w + x];

						float variance = 0.0f, avgNormalLength = 0.0f;


						if (channel.UseNormals && normalMap != null) {
							Vector4 normal = GetChannels(normalMap, u, v, mipLevel, w, h, rangeX, rangeY);
							normal.x = (normal.x * 2.0f) - 1.0f;
							normal.y = (normal.y * 2.0f) - 1.0f;
							normal.z = (normal.z * 2.0f) - 1.0f;

							avgNormalLength = ((Vector3)normal).magnitude;
							float avgNormLen2 = avgNormalLength * avgNormalLength;
							float kappa = (3.0f * avgNormalLength - avgNormalLength * avgNormLen2) / (1.0f - avgNormLen2);
							variance = Mathf.Clamp01((1.0f / (2.0f * kappa)) - source.VarianceBias);
						}

						for (int i = 0; i < outIndices.Length; ++i) {
							int storeIndex = outIndices[i];

							var tex = maps[storeIndex];
							var channelVal = source.ChannelValues[storeIndex];

							float input = 0.0f;

							if (channel.OutputVariance) {
								input = variance;
							} else if (inIndices.Length > 0) {
								int read = inIndices[Mathf.Min(i, inIndices.Length - 1)];
								input = GetChannel(tex, channelVal, linear[storeIndex], u, v, mipLevel, rangeX, rangeY, read);
							} 

							if (channel.RoughnessCorrect) {
								// Specular AA for Beckmann roughness.
								// cf http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf pg92
								if (avgNormalLength < 1.0f) {
									float a = input * input;
									a = Mathf.Sqrt(Mathf.Clamp01(a * a + variance));
									input = Mathf.Sqrt(a);
								}
							}

							if (source.DoInvert[storeIndex]) {
								input = 1.0f - input;
							}

							col[storeIndex] = input;
						}

						colors[y * w + x] = col;
					}
				}
			}

			target.SetPixels(colors, mipLevel);
		}
	}
}