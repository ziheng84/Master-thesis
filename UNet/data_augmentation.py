import numpy as np
import imgaug as ia
import imgaug.augmenters as iaa
from sklearn.utils import shuffle
from matplotlib import pyplot as plt
import os


# def augmentation(x_train):
#     ia.seed(1)
#
#     # Flip 50% all images horizontally
#     flip = ia.augmenters.Fliplr(p=0.5)
#     x_train = flip.augment_images(images=x_train)
#
#     seq = ia.augmenters.Sequential([
#         # 10% gaussian blur with random sigma between 0 and 0.2.
#         ia.augmenters.Sometimes(0.1, ia.augmenters.GaussianBlur(sigma=(0, 0.2))),
#         # strengthen or weaken contrast by a factor of 0.9 to 1.1
#         ia.augmenters.ContrastNormalization((0.9, 1.1)),
#         # Make some images brighter and some darker, multiply each image with a random value between 0.5 and 1.1
#         ia.augmenters.Multiply((0.5, 1.1)),
#         # Apply affine transformations to each image.
#         ia.augmenters.Affine(
#             scale=(0.8, 1.1),
#             translate_percent={'x': (-0.05, 0.05), 'y': (-0.05, 0.05)},
#             shear=(-5, 5)
#         )
#     ], random_order=True)  # apply augmenters in random order
#
#     x_train_aug = seq.augment_images(x_train)
#
#     return x_train_aug


def augmentation(x_train, y_train, flip='horizontal', enlarge=True, droplet=False):
    ia.seed(88)  # global random seed

    # flip and affine augmentations must perform on x and y at the same time due to semantic segmentation nature,
    # while other augmentations must only perform on x, otherwise the labels are affected

    # First, flip all images horizontally
    if flip == 'horizontal':
        flip = iaa.Fliplr(p=1.0)
        x_train_aug = flip.augment_images(images=x_train)
        y_train_aug = flip.augment_images(images=y_train)
    elif flip == 'vertical':
        flip = iaa.Flipud(p=1.0)
        x_train_aug = flip.augment_images(images=x_train)
        y_train_aug = flip.augment_images(images=y_train)
    else:
        x_train_aug = x_train
        y_train_aug = y_train
        assert not enlarge, 'when no flip, enlarge should be False to prevent duplicate data'

    # Second, apply none affine augmentations only on x
    seq = iaa.Sequential([
        # 50% gaussian blur with random sigma between 0 and 0.2.
        iaa.Sometimes(0.5, iaa.GaussianBlur(sigma=(0, 0.2))),
        # strengthen or weaken contrast by a factor of 0.9 to 1.1
        iaa.ContrastNormalization((0.9, 1.1)),
        # Make some images brighter and some darker, multiply each image with a random value between 0.8 and 1.2
        iaa.Multiply((0.8, 1.2)),
        # Drop 0% to 1% of pixels as square boxed sized from 1x1 to 2x2
        #iaa.CoarseDropout((0.0, 0.01), size_percent=(0.0, 0.5))
    ], random_order=True)  # apply augmenters in random order
    x_train_aug = seq.augment_images(images=x_train_aug)

    # Third, apply affine transformations as a new sequence to ensure the same transformation on y as well.
    if droplet:
        affine = ia.augmenters.Affine(
                                      translate_percent={'x': (-0.2, 0.2), 'y': (-0.2, 0.2)},
                                      mode='constant', cval=0
                                      )
    else:
        affine = ia.augmenters.Affine(scale=(0.95, 1.05),
                                      translate_percent={'x': (-0.01, 0.01), 'y': (-0.01, 0.01)},
                                      shear=(-0.5, 0.5),
                                      rotate=(-0.5, 0.5)
                                      )

    # combine train and mask into one array to ensure the same augmentation
    combine_train_mask = np.append(x_train_aug, y_train_aug, axis=-1)
    combine_aug = affine.augment_images(images=combine_train_mask)
    # extract x_train_aug and y_train_aug separately from 2-channel combine_aug
    x_train_aug = combine_aug[:, :, :, :1]
    y_train_aug = combine_aug[:, :, :, 1:]

    if enlarge:
        x_train_aug, y_train_aug = concat_aug_data(x_train, x_train_aug, y_train, y_train_aug)

    return x_train_aug, y_train_aug


def concat_aug_data(x_train, x_train_aug, y_train, y_train_aug):
    x_train = np.append(x_train, x_train_aug, axis=0)
    y_train = np.append(y_train, y_train_aug, axis=0)
    # shuffle to keep randomness in training process
    x_train, y_train = shuffle(x_train, y_train, random_state=0)

    return x_train, y_train


def aug_visual(x, x_aug, y_aug, num_show=2, save=False, save_dir=None):
    try:
        assert x.shape == x_aug.shape
    except AssertionError:
        print('augment parameter enlarge should be False for visualization')
        exit()

    num = np.random.choice(np.arange(x_aug.shape[0]), num_show, replace=False)

    fig, axs = plt.subplots(3, num_show, figsize=(10, 6), sharey='row', sharex='col')
    fig.subplots_adjust(hspace=0.2, wspace=0.3, left=0.07, right=0.95, bottom=0.1, top=0.9)

    for i, c in enumerate(range(num_show)):
        axs[0, c].imshow(x[num[i], :, :, 0], cmap='gray', label='input image')
        axs[0, c].set_title('original')
        axs[0, c].tick_params(bottom=False, left=False)

        axs[1, c].imshow(x_aug[num[i], :, :, 0], cmap='gray', label='input image')
        axs[1, c].set_title('augmented')
        axs[1, c].tick_params(bottom=False, left=False)

        axs[2, c].imshow(y_aug[num[i], :, :, 0], cmap='gray', label='ground_truth')
        axs[2, c].set_title('augmented mask')
        axs[2, c].tick_params(bottom=False, left=False)

        for j in range(3):
            for spine in axs[j, c].spines.values():
                spine.set_visible(False)

    if save:
        if save_dir is None:
            save_dir = os.getcwd()
        if not os.path.exists(save_dir):
            os.makedirs(save_dir)

        fig.savefig(save_dir + '/aug_visual.pdf')


def droplet_augmentation(x_train, y_train, enlarge=True):
    x_train_aug, y_train_aug = augmentation(x_train, y_train, flip='horizontal', enlarge=enlarge, droplet=True)
    x_train_aug, y_train_aug = augmentation(x_train_aug, y_train_aug, flip='vertical', enlarge=enlarge, droplet=True)

    return x_train_aug, y_train_aug
