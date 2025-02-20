# AdjustableLimitedWatershed
An ImageJ/FIJI plugin (GUI and headless available) that implements the watershed algorithm with a number of optional parameters. These include an adjustable tolerance, limiting the length of the lines created by the watershed algorithm, whether or not to restrict to black, gaussian smoothing, and the option to set an EDM threshold.

The watershed algorithm can help with image segmentation. This is not a particularly good example, but it will get the point across. Here is an original image:

![cells](https://github.com/user-attachments/assets/043a9388-6f74-497a-a4d9-3acaa97213a3)

After auto-thresholding, we get the following image:

![cells_autothresh](https://github.com/user-attachments/assets/adaa04e3-df18-40cb-8810-a9614d4bf530)

Applying watershed with the imagej default of 0.5 for the tolerance then gets us this:

![cell_authothresh_watershednolimit](https://github.com/user-attachments/assets/e036b703-11cd-43ec-b528-7bb3184a197a)

Sometimes, there is a need to have the extra segmentation lines created by the watershed algorithm to be size-limited so that the tolerance value is good in general but that no incorrect segmenation lines are created (for example, in some situations a line being too long in pixel length could indicate an otherwise incorrect segmentation). Below, we isolate and filter the watershed-created lines.

![Isolated_Watershed_Lines](https://github.com/user-attachments/assets/4e5f3939-37c5-4619-b2e2-2fe7fe0f5fb5)


![Filtered_Watershed_Lines](https://github.com/user-attachments/assets/f2902878-d8a2-4aa9-81fd-3bca0c7288b6)

The filtered watershedding then produces the following image.

![watershedlimited](https://github.com/user-attachments/assets/a46a1931-2884-4966-a960-cc90f45524e4)

The program is available as both a plugin and an imagej macro. The plugin is designed to be headless and can be run from python or other scripting languages. The imagej macro is designed to use the ImageJ/FIJI Gui and provides you the following dialog options (all also available in the headless plugin).

![image](https://github.com/user-attachments/assets/8eca0ffc-2df3-4a6e-9cbf-46c1e6a89b8b)
