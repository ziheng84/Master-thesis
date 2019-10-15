model-lab-unet-1:
First version

model-lab-unet-scratch:
No preprocessing
Loss: bce_dice_loss
Output: sigmoid
Metrics: IoU


model-lab-unet-bce_dice_loss:
Revised version
Loss: bce_dice_loss
Output: sigmoid
Metrics: IoU
validation_split=0.1, batch_size=16, epochs=50, EarlyStopping(patience=5)
Epochs 31, 29min3s


model-lab-Ls-unet-epoch50
Training:49, val:6
Loss: bce_dice_loss
Output: sigmoid
Metrics: IoU
validation_split=0.1, batch_size=8, epochs=50, EarlyStopping(patience=5)
3min


model-lab-Ls-unet-epoch75
EarlyStopping(patience=8)


model-Swain-unet-epoch100
Training:93, val:11
Loss: bce_dice_loss
Output: sigmoid
Metrics: IoU
validation_split=0.1, batch_size=8
25min

