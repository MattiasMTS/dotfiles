use std::path::PathBuf;

use gameboy::gameboy::Gameboy;
use gameboy::KeypadKey;
use napi::bindgen_prelude::{Buffer, Error, Result, Status};
use napi_derive::napi;

#[napi]
pub struct NativeGameboy {
    gameboy: Option<Gameboy>,
}

#[napi]
impl NativeGameboy {
    #[napi(constructor)]
    pub fn new(rom: Buffer, rom_path: Option<String>) -> Result<Self> {
        if rom.is_empty() {
            return Err(Error::new(Status::InvalidArg, "ROM buffer is empty"));
        }

        let path = rom_path.map(PathBuf::from);
        Ok(Self {
            gameboy: Some(Gameboy::new(rom.to_vec(), path)),
        })
    }

    #[napi]
    pub fn step_frame(&mut self) -> Result<()> {
        self.gameboy_mut()?.frame();
        Ok(())
    }

    #[napi]
    pub fn get_frame_buffer(&self) -> Result<Buffer> {
        Ok(Buffer::from(self.gameboy_ref()?.image().to_vec()))
    }

    #[napi]
    pub fn set_button(&mut self, button: String, pressed: bool) -> Result<()> {
        let key = parse_button(&button)?;
        let gameboy = self.gameboy_mut()?;
        if pressed {
            gameboy.keydown(key);
        } else {
            gameboy.keyup(key);
        }
        Ok(())
    }

    #[napi]
    pub fn dispose(&mut self) {
        self.gameboy.take();
    }
}

impl NativeGameboy {
    fn gameboy_ref(&self) -> Result<&Gameboy> {
        self.gameboy
            .as_ref()
            .ok_or_else(|| Error::new(Status::GenericFailure, "Gameboy instance is disposed"))
    }

    fn gameboy_mut(&mut self) -> Result<&mut Gameboy> {
        self.gameboy
            .as_mut()
            .ok_or_else(|| Error::new(Status::GenericFailure, "Gameboy instance is disposed"))
    }
}

fn parse_button(button: &str) -> Result<KeypadKey> {
    match button.to_ascii_lowercase().as_str() {
        "right" => Ok(KeypadKey::Right),
        "left" => Ok(KeypadKey::Left),
        "up" => Ok(KeypadKey::Up),
        "down" => Ok(KeypadKey::Down),
        "a" => Ok(KeypadKey::A),
        "b" => Ok(KeypadKey::B),
        "select" => Ok(KeypadKey::Select),
        "start" => Ok(KeypadKey::Start),
        _ => Err(Error::new(
            Status::InvalidArg,
            format!("Unknown Game Boy button: {button}"),
        )),
    }
}
